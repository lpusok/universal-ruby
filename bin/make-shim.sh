#!/usr/bin/env bash

PARENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
source "${PARENT_DIRECTORY}/util.sh"

main() {
	symlink_libyaml "." "$(dirname "$PARENT_DIRECTORY")"
	fix_mkconfig "$PARENT_DIRECTORY" "."
	make $@
}

main "$@"
