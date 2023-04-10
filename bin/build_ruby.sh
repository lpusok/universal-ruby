#!/usr/bin/env bash

set -eo pipefail

PARENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

download_files() {
	# Params
	local build_dir="${1:?Missing build directory}"
	local ruby_version="${2:?Missing Ruby version}"

	local ruby_short_version="${ruby_version:0:${#ruby_version}-2}"
	cd "$build_dir"

	if [[ ! -d "yaml-0.2.5" ]]; then
		echo "Downloading libyaml"
		curl "http://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz" \
			--location \
			-o "libyaml.tar.gz"
		tar -xf libyaml.tar.gz
	fi

	if [[ ! -d "ruby-${ruby_version}" ]]; then
		echo "Downloading Ruby ${ruby_version}"
		curl "https://cache.ruby-lang.org/pub/ruby/${ruby_short_version}/ruby-${ruby_version}.tar.gz" \
			--location \
			-o "ruby.tar.gz"
		tar -xf ruby.tar.gz
	fi
}

build_libyaml() {
	local build_dir="${1:?Missing build directory}"
	local artifacts_prefix="${2:?Missing artifacts prefix}"

	local expected="${build_dir}/yaml-0.2.5"
	if [[ ! -d "$expected" ]]; then
		echo "Missing yaml source"
		exit 1
	fi

	if [[ -d "${artifacts_prefix}/libyaml" ]]; then
		echo "libyaml exists; ignoring compilation"
		return
	fi

	cd "$expected"
	./configure --prefix="${artifacts_prefix}/libyaml"
	make -j4
	make install
}

build_with_rbenv() {
	local artifacts_prefix="${1:?Missing artifacts prefix}"
	local ruby_version="${2:?Missing Ruby version}"

	RUBY_CONFIGURE_OPTS="--with-arch=x86_64,arm64 --prefix=${artifacts_prefix}/ruby-${ruby_version} --disable-install-doc --enable-shared" \
	RUBY_CFLAGS="-Wno-error=implicit-function-declaration" \
		rbenv install $ruby_version
}

build_ruby() {
	local build_dir="${1:?Missing build directory}"
	local artifacts_prefix="${2:?Missing artifacts prefix}"
	local ruby_version="${3:?Missing Ruby version}"

	local expected="${build_dir}/ruby-${ruby_version}"
	if [[ ! -d "$expected" ]]; then
		echo "Missing Ruby source"
		exit 1
	fi

	cd "$expected"
	./configure \
		LDFLAGS="-L${artifacts_prefix}/libyaml/lib $LDFLAGS" \
		CFLAGS="-I${artifacts_prefix}/libyaml/include $CFLAGS" \
		--prefix="${artifacts_prefix}/ruby-${ruby_version}" \
		--enable-shared

		# --with-arch
		#   --target=TARGET
	make
	make install

}

main() {
	local ruby_version="${1:-3.2.2}"

	local build_dir="$(cd "${PARENT_DIRECTORY}/../.build"; pwd)"
	local artifacts_prefix="${build_dir}/artifacts/$(uname -m)"
	mkdir -p "$build_dir"


	download_files "$build_dir" $ruby_version
	# build_libyaml "$build_dir" "$artifacts_prefix"
	build_ruby "$build_dir" "$artifacts_prefix" $ruby_version
}

main "$@"
