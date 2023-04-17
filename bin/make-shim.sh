#!/usr/bin/env bash

PARENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "${PARENT_DIRECTORY}/util.sh"

main() {
	# symlink_libyaml "." "$(dirname "$PARENT_DIRECTORY")"
	if [[ -f ruby.c ]]; then
		# Only run in Ruby root directory
		copy_replacements "${PARENT_DIRECTORY}/replacements/ruby/3.2.2/" "./"
	fi
	make "$@"
}

main "$@"
