symlink_libyaml() {
	local ruby_src_dir="${1:?Missing Ruby source directory}"
	local search_path="${2:?Missing libyaml search path}"

	if [[ ! -f "${ruby_src_dir}/libyaml-0.2.dylib" ]]; then
		# Ruby doesn't recognize the with-libyaml-dir when loading Psych
		local libyaml="$(find "$search_path" -name libyaml-0.2.dylib)"
		if [[ ! -e "$libyaml" ]]; then
			echo "Could not find libyaml-0.2.dylib in $lib_dir!"
			exit 1
		fi
		ln -s "$libyaml" "${ruby_src_dir}/libyaml-0.2.dylib"
	fi
}
