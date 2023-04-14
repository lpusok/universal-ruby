#!/usr/bin/env bash

PARENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "${PARENT_DIRECTORY}/util.sh"

main() {
	# symlink_libyaml "." "$(dirname "$PARENT_DIRECTORY")"
	if [[ -f ruby.c ]]; then
		# Only run in Ruby root directory
		fix_mkconfig "$PARENT_DIRECTORY" "."
	fi
	make "$@"
}

main "$@"
