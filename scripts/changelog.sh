#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2


# Loading .env file (if exists):
if [ -f ".env" ]; then
	# shellcheck disable=SC1091
	source .env
fi


if [ -z "$(which gh)" ]; then
	echo "[ERROR]: 'gh' not found or not installed!"
	exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "[ERROR]: You need to login: 'gh auth login'!"
    exit 1
fi
## --- Base --- ##


## --- Variables --- ##
# Load from envrionment variables:
CHANGELOG_FILE_PATH="${CHANGELOG_FILE_PATH:-./CHANGELOG.md}"
RELEASE_NOTES_FILE_PATH="${RELEASE_NOTES_FILE_PATH:-./docs/release-notes.md}"

# Flags:
_IS_COMMIT=false
_IS_PUSH=false
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-c | --commit)
					_IS_COMMIT=true
					shift;;
				-p | --push)
					_IS_PUSH=true
					shift;;
				*)
					echo "[ERROR]: Failed to parse input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -c, --commit | -p, --push"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ "${_IS_COMMIT}" == true ]; then
		if [ -z "$(which git)" ]; then
			echo "[ERROR]: 'git' not found or not installed!"
			exit 1
		fi
	fi


	local _changelog_title="# Changelog"
	local _release_tag _release_notes _release_entry
	_release_tag=$(gh release view --json tagName -q ".tagName")
	_release_notes=$(gh release view --json body -q ".body")
	_release_entry="## ${_release_tag} ($(date '+%Y-%m-%d'))\n\n${_release_notes}"

	echo "[INFO]: Updating changelog..."
	if ! grep -q "^${_changelog_title}" "${CHANGELOG_FILE_PATH}"; then
		echo -e "${_changelog_title}\n\n" > "${CHANGELOG_FILE_PATH}"
	fi

	local _tail_changelog
	_tail_changelog=$(tail -n +3 "${CHANGELOG_FILE_PATH}")
	echo -e "${_changelog_title}\n\n${_release_entry}\n\n${_tail_changelog}" > "${CHANGELOG_FILE_PATH}"
	echo "[OK]: Updated changelog version: '${_release_tag}'"


	echo "[INFO]: Updating release notes..."
	local _release_notes_header="---\ntitle: Release Notes\nhide:\n  - navigation\n---\n\n# 📌 Release Notes"
	if ! grep -q "^# 📌 Release Notes" "${RELEASE_NOTES_FILE_PATH}"; then
		echo -e "${_release_notes_header}\n\n" > "${RELEASE_NOTES_FILE_PATH}"
	fi

	local _tail_notes
	_tail_notes=$(tail -n +9 "${RELEASE_NOTES_FILE_PATH}")
	echo -e "${_release_notes_header}\n\n${_release_entry}\n\n${_tail_notes}" > "${RELEASE_NOTES_FILE_PATH}"
	echo "[OK]: Updated release notes with version: '${_release_tag}'"

	if [ "${_IS_COMMIT}" == true ]; then
		echo "[INFO]: Committing changelog version '${_release_tag}'..."
		git add "${CHANGELOG_FILE_PATH}" || exit 2
		git add "${RELEASE_NOTES_FILE_PATH}" || exit 2
		git commit -m "docs: update changelog version '${_release_tag}'." || exit 2
		echo "[OK]: Done."

		if [ "${_IS_PUSH}" == true ]; then
			echo "[INFO]: Pushing '${_release_tag}'..."
			git push || exit 2
			echo "[OK]: Done."
		fi
	fi
}

main "${@:-}"
## --- Main --- ##
