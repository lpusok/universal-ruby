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

find_real() {
	local basename="${1:?Failed to provide basename}"
	local shim_parent_dir="${2:?Failed to provide shim parent directory}"

	local real
	while IFS=: read -d: -r entry; do
		found="$(find "$entry" -name $1)"
		if [[ -n $found && "$found" != $shim_parent_dir* ]]; then
			real="$found"
			break
		fi
	done <<< "$PATH"

	echo $real
}

caching_real_path() {
	local basename=$(basename "$1")
	local expected="${2}/real_${basename}"
	local real_path=
	if [[ -f "$expected" ]]; then
		real_path=$(<"$expected")
	else
		local found=$(find_real "$basename" "$2")
		echo $found > "$expected"
		real_path="$found"
	fi
	echo $real_path
}

is_rosetta() {
	if [[ $(sysctl -n sysctl.proc_translated) -eq 1 ]]; then
		echo "y"
	fi
}
