symlink_libyaml() {
	local ruby_src_dir="${1:?Missing Ruby source directory}"
	local search_path="${2:?Missing libyaml search path}"

	if [[ ! -f "${ruby_src_dir}/libyaml-0.2.dylib" ]]; then
		# Ruby doesn't recognize the with-libyaml-dir when loading Psych
		local libyaml="$(find "$search_path" -name libyaml-0.2.dylib | head -n1)"
		if [[ ! -e "$libyaml" ]]; then
			echo "Could not find libyaml-0.2.dylib in $search_path!"
			exit 1
		fi
		ln -s "$libyaml" "${ruby_src_dir}/libyaml-0.2.dylib"
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
