#!/usr/bin/env bash

set -eo pipefail

PARENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "${PARENT_DIRECTORY}/util.sh"

download_files() {
	# Params
	local src_dir="${1:?Missing src directory}"
	local ruby_version="${2:?Missing Ruby version}"

	local ruby_short_version="${ruby_version:0:${#ruby_version}-2}"
	cd "$src_dir"

	if [[ ! -d "yaml-0.2.5" ]]; then
		echo "Downloading libyaml"
		curl "http://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz" \
			--location \
			-o "libyaml.tar.gz"
		tar -xf libyaml.tar.gz
	fi

	if [[ ! -d "openssl-3.1.0" ]]; then
		echo "Downloading OpenSSL"
		curl "https://www.openssl.org/source/openssl-3.1.0.tar.gz" \
			--location \
			-o openssl.tar.gz
		tar -xf openssl.tar.gz
	fi

	if [[ ! -d "ruby-${ruby_version}" ]]; then
		echo "Downloading Ruby ${ruby_version}"
		curl "https://cache.ruby-lang.org/pub/ruby/${ruby_short_version}/ruby-${ruby_version}.tar.gz" \
			--location \
			-o "ruby.tar.gz"
		tar -xf ruby.tar.gz
	fi
}

fix_mkconfig() {
	# File taken from: https://github.com/ruby/ruby/blob/master/tool/mkconfig.rb
	# There's a bug in the regex for determining the `arch` from the flags.
	# Specifically the \z constraint causes the substring lookup to fail and
	# result in nil.  The latest version allows for the `cpu` backup from the
	# platform.
	local origin_dir="${1:?Missing origin directory}"
	local ruby_src_dir="${2:?Missing Ruby source directory}"

	cp "${origin_dir}/mkconfig.rb" "${ruby_src_dir}/tool/mkconfig.rb"
}

build_libyaml() {
	local src_dir="${1:?Missing build directory}"
	local lib_dir="${2:?Missing lib prefix}"

	local expected="${src_dir}/yaml-0.2.5"
	if [[ ! -d "$expected" ]]; then
		echo "Missing yaml source"
		exit 1
	fi

	if [[ -d "${lib_dir}/libyaml" ]]; then
		echo "libyaml exists; ignoring compilation"
		return
	fi

	cd "$expected"
	./configure --prefix="${lib_dir}/libyaml" CFLAGS="-arch x86_64 -arch arm64"
	make -j4
	make install
}

build_openssl() {
	local src_dir="${1:?Missing src directory}"
	local lib_dir="${2:?Missing lib prefix}"

	local expected="${src_dir}/openssl-3.1.0"
	if [[ ! -d "$expected" ]]; then
		echo "Missing openssl source"
		exit 1
	fi

	if [[ -d "${lib_dir}/openssl/universal" ]]; then
		echo "openssl exists; ignoring compilation"
		return
	fi

	cd "$expected"


	# Multi-arch: https://stackoverflow.com/questions/25530429/build-multiarch-openssl-on-os-x/25531033#25531033
	# Note: Cleaned up and removed deprecated options/outdated items

	# Native (arm64)
	make clean
	./config --prefix="${lib_dir}/openssl/arm64"
	make -j4
	make install

	# Intel
	make clean
	./configure --prefix="${lib_dir}/openssl/x86_64" darwin64-x86_64-cc
	make -j4
	make install

	# Combine
	local ulib="${lib_dir}/openssl/universal/lib"
	local armlib="${lib_dir}/openssl/arm64/lib"
	mkdir -p "${ulib}"/{engines-3,ossl-modules}
	local binaries="$(find "${armlib}" -name "*.dylib" -o -name "*.a")"
	for bin in ${binaries[@]}; do
		local binname="${bin/$armlib/}"
		binname="${binname#/}"
		local x86path="${lib_dir}/openssl/x86_64/lib/${binname}"
		lipo -create "$bin" "$x86path" -output "${ulib}/${binname}"
	done

	cd "$(dirname "$armlib")"
	cp -r {bin,include,share,ssl} "${lib_dir}/openssl/universal/"
}

install_psych() {
	if [[ -z $(gem list --local | grep psych) ]]; then
		echo "Installing psych gem"
		gem install psych
	fi
}

verify_deps_prior_to_building_ruby() {
	while [[ $# -gt 0 ]]; do
		if [[ ! -d "$1" ]]; then
			echo "Missing library folder: $1"
			exit 1
		fi
		shift
	done
}

build_with_rbenv() {
	local artifacts_prefix="${1:?Missing artifacts prefix}"
	local ruby_version="${2:?Missing Ruby version}"

	RUBY_CONFIGURE_OPTS="--with-arch=x86_64,arm64 --prefix=${artifacts_prefix}/ruby-${ruby_version} --disable-install-doc --enable-shared" \
	RUBY_CFLAGS="-Wno-error=implicit-function-declaration" \
		rbenv install $ruby_version
}

build_ruby() {
	local src_dir="${1:?Missing src directory}"
	local lib_dir="${2:?Missing lib prefix}"
	local ruby_version="${3:?Missing Ruby version}"

	local expected="${src_dir}/ruby-${ruby_version}"
	if [[ ! -d "$expected" ]]; then
		echo "Missing Ruby source"
		exit 1
	fi

	local openssl_dir="${lib_dir}/openssl/universal/"
	local libyaml_dir="${lib_dir}/libyaml/"
	verify_deps_prior_to_building_ruby "$openssl_dir" "$libyaml_dir"

	cd "$expected"
	make clean
	./configure \
		--with-openssl-dir="${openssl_dir}" \
		--with-libyaml-dir="${libyaml_dir}" \
		--with-destdir="${lib_dir}/ruby-${ruby_version}" \
		--enable-shared \
		--with-arch=arm64,x86_64 \
		--disable-install-rdoc \
			| tee _ruby-configure.log

	make | tee _ruby-make.log
	make install | tee _ruby-make-install.log
}

main() {
	local ruby_version="${1:-3.2.2}"

	local repo_dir="$(cd "${PARENT_DIRECTORY}/../"; pwd)"

	mkdir -p "$repo_dir/.build"
	local build_dir="$(cd "${repo_dir}/.build"; pwd)"
	local src_dir="${build_dir}/src"
	local lib_dir="${build_dir}/lib"
	mkdir -p "$build_dir"/{src,lib,artifacts}

	download_files "$src_dir" $ruby_version
	build_libyaml "$src_dir" "$lib_dir"
	build_openssl "$src_dir" "$lib_dir"

	fix_mkconfig "$PARENT_DIRECTORY" "${src_dir}/ruby-${ruby_version}"
	build_ruby "$src_dir" "$lib_dir" $ruby_version
}

main "$@"
