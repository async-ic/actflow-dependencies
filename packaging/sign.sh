#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ole Richter - Technical University of Denmark
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Sourced, not executed, after relocate.sh (is_macho).
#
#   gpg_sign <file>      detached armoured signature -> <file>.asc
#   gpg_verify <file>    <file> against <file>.asc
#   codesign_tree <root> every mach-o image under <root>
#   macos_dmg <root> <dmg> act/ + README.md as a signed, notarized, stapled dmg
#
# CI injects the credentials as protected file variables, present on the default branch
# and on tags only. Their presence is the gate: each entry point skips what it has no
# credential for, and fails the job on a bad signature, an unsignable image or a
# rejected notarization.
#
#   ACTFLOW_GPG_KEY      file  private key, passphrase-less (el7 ships gpg 2.0)
#   ACTFLOW_GPG_PUBKEY   file  public key the downloads are verified against
#   MACOS_CERT_P12       file  Developer ID Application certificate + key
#   MACOS_CERT_PASSWORD  var   its export password
#   MACOS_SIGN_IDENTITY  var   "Developer ID Application: <name> (<team id>)"
#   MACOS_ASC_KEY        file  App Store Connect api key (.p8)
#   MACOS_ASC_KEY_ID     var   its key id
#   MACOS_ASC_ISSUER_ID  var   its issuer id

_SIGN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# $1 credential variable name, $2 what it is for
_have_cred() {
	local path=${!1:-}
	[ -n "$path" ] && [ -f "$path" ] && return 0
	echo "$1 not injected, skipping $2"
	return 1
}

# gpg in a throwaway home, the runner keyring stays untouched.
# $1 key to import, rest the gpg arguments
_gpg() {
	local key=$1 home rc
	shift
	home=$(mktemp -d)
	gpg --batch --quiet --homedir "$home" --import "$key" &&
		gpg --batch --quiet --homedir "$home" "$@"
	rc=$?
	rm -rf "$home"
	return $rc
}

# $1 -> $1.asc
gpg_sign() {
	_have_cred ACTFLOW_GPG_KEY "artifact signing" || return 0
	rm -f "$1.asc"
	_gpg "$ACTFLOW_GPG_KEY" --armor --detach-sign --output "$1.asc" "$1" ||
		{ echo "gpg: signing $1 failed" >&2; exit 1; }
	echo "signed $1 -> $1.asc"
}

# $1 against $1.asc; missing or bad is fatal
gpg_verify() {
	_have_cred ACTFLOW_GPG_PUBKEY "download verification" || return 0
	[ -f "$1.asc" ] || { echo "gpg: $1 has no signature" >&2; exit 1; }
	# the injected key is the trust anchor, not the web of trust
	_gpg "$ACTFLOW_GPG_PUBKEY" --trust-model always --verify "$1.asc" "$1" ||
		{ echo "gpg: bad signature for $1" >&2; exit 1; }
	echo "verified $1"
}

_keychain=

# job-scoped keychain holding MACOS_CERT_P12; codesign resolves the identity through
# the user search list
_keychain_open() {
	local pass
	_keychain="$(pwd)/actflow-signing.keychain-db"
	pass=$(uuidgen)
	security create-keychain -p "$pass" "$_keychain"
	security set-keychain-settings -lut 21600 "$_keychain"
	security unlock-keychain -p "$pass" "$_keychain"
	security import "$MACOS_CERT_P12" -k "$_keychain" -P "${MACOS_CERT_PASSWORD:-}" \
		-T /usr/bin/codesign
	security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$pass" \
		"$_keychain" >/dev/null
	security list-keychains -d user -s "$_keychain" $(security list-keychains -d user | tr -d '" ')
}

_keychain_close() {
	security delete-keychain "$_keychain"
	_keychain=
}

# $1 install root (default $ACT_HOME). Covers shared libraries, plugin bundles and
# executables. Runs after the last relocate_tree, install_name_tool replaces the
# signature with an ad-hoc one. An unsignable image fails the job.
codesign_tree() {
	local root=${1:-$ACT_HOME} f rc=0
	[ "$(uname -s)" = "Darwin" ] || return 0
	_have_cred MACOS_CERT_P12 "macOS code signing" || return 0
	_keychain_open

	echo "#### signing mach-o images under $root ####"
	while IFS= read -r -d '' f; do
		is_macho "$f" || continue
		codesign --force --timestamp --options runtime \
			--entitlements "${_SIGN_DIR}/macos_entitlements.plist" \
			--keychain "$_keychain" --sign "$MACOS_SIGN_IDENTITY" "$f" ||
			{ echo "codesign failed: ${f#$root/}" >&2; rc=1; }
	done < <(find "$root" -type f -print0)

	_keychain_close
	[ $rc -eq 0 ] || { echo "refusing to package: not every image could be signed" >&2; exit 1; }
}

# $1 install root, $2 output dmg: <root> as act/ at the top with its README.md beside
# it, signed, notarized and stapled. Non-zero without a certificate, the caller then
# falls back to a tarball.
macos_dmg() {
	local root=$1 out=$2 stage
	[ "$(uname -s)" = "Darwin" ] || return 1
	_have_cred MACOS_CERT_P12 "macOS dmg packaging" || return 1

	# hardlinks, the tree is ~1GB and lands on the same filesystem
	stage="$(dirname "$out")/.dmg-stage"
	rm -rf "$stage" "$out"
	mkdir -p "$stage"
	cp -Rl "$root" "$stage/act" 2>/dev/null || cp -R "$root" "$stage/act"
	cp "$root/README.md" "$stage/README.md" 2>/dev/null || true
	hdiutil create -quiet -srcfolder "$stage" -volname actflow -format UDZO "$out" ||
		{ echo "dmg: hdiutil create failed" >&2; exit 1; }
	rm -rf "$stage"

	_keychain_open
	codesign --force --timestamp --keychain "$_keychain" --sign "$MACOS_SIGN_IDENTITY" "$out" ||
		{ _keychain_close; echo "dmg: signing failed" >&2; exit 1; }
	_keychain_close

	_have_cred MACOS_ASC_KEY "macOS notarization" || return 0
	xcrun notarytool submit "$out" --key "$MACOS_ASC_KEY" \
		--key-id "$MACOS_ASC_KEY_ID" --issuer "$MACOS_ASC_ISSUER_ID" --wait ||
		{ echo "notarize: submission rejected" >&2; exit 1; }
	xcrun stapler staple "$out" || { echo "notarize: stapling failed" >&2; exit 1; }
	echo "packaged $out"
}
