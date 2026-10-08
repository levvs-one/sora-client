#!/bin/sh
# Installs Sora on Linux in one command:
#
#   curl -fsSL https://github.com/levvs-one/sora-client/releases/latest/download/install.sh | sh
#
# It finds the latest release, downloads the packages for this distribution
# and processor, checks them against the release's SHA256SUMS and installs
# them with the system's package manager, so updates and removal stay the
# package manager's too. Nothing is installed when a checksum does not match.
#
# SORA_VERSION=1.0.3 installs that release instead of the latest.
# SORA_DIST=<directory> installs packages already in that directory, with
# their SHA256SUMS; CI checks the packages it built this way.
set -eu

repo=https://github.com/levvs-one/sora-client

say() { printf '%s\n' "$*"; }
die() {
	printf 'sora: %s\n' "$*" >&2
	exit 1
}

case "$(uname -m)" in
x86_64 | amd64) deb_arch=amd64 rpm_arch=x86_64 arch_arch=x86_64 with_app=yes ;;
aarch64 | arm64) deb_arch=arm64 rpm_arch=aarch64 arch_arch=aarch64 with_app=no ;;
*) die "no Sora build for $(uname -m)" ;;
esac

if command -v apt-get >/dev/null 2>&1; then
	manager=apt
elif command -v dnf >/dev/null 2>&1; then
	manager=dnf
elif command -v zypper >/dev/null 2>&1; then
	manager=zypper
elif command -v pacman >/dev/null 2>&1; then
	manager=pacman
else
	die "no apt, dnf, zypper or pacman here; download a package from $repo/releases"
fi

if [ "$(id -u)" -eq 0 ]; then
	as_root=""
elif command -v sudo >/dev/null 2>&1; then
	as_root=sudo
else
	die "installing packages needs root, and there is no sudo"
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

fetch() { curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1"; }

if [ -n "${SORA_DIST:-}" ]; then
	version=${SORA_VERSION:?SORA_VERSION is needed with SORA_DIST}
else
	if [ -z "${SORA_VERSION:-}" ]; then
		# The latest release redirects to its tag; no API call, no rate limit.
		latest=$(curl -fsSLI --proto '=https' -o /dev/null -w '%{url_effective}' "$repo/releases/latest")
		version=${latest##*/v}
		case "$version" in
		[0-9]*.[0-9]*.[0-9]*) ;;
		*) die "could not tell the latest release from $latest" ;;
		esac
	else
		version=$SORA_VERSION
	fi
fi

case "$manager" in
apt) files="sora-core_${version}_${deb_arch}.deb" app="sora_${version}_${deb_arch}.deb" ;;
dnf | zypper) files="sora-core-${version}-1.${rpm_arch}.rpm" app="sora-${version}-1.${rpm_arch}.rpm" ;;
pacman)
	# A pacman version has no "~"; a build between releases loses it.
	pkgver=$(printf '%s' "$version" | tr -d '~')
	files="sora-core-${pkgver}-1-${arch_arch}.pkg.tar.zst" app="sora-${pkgver}-1-${arch_arch}.pkg.tar.zst"
	;;
esac
if [ "$with_app" = yes ]; then
	files="$files $app"
else
	say "sora: this processor gets the core only; the app is built for x86_64"
fi

say "sora: installing $version with $manager"
for name in SHA256SUMS $files; do
	if [ -n "${SORA_DIST:-}" ]; then
		cp "$SORA_DIST/$name" "$work/$name" || die "$name is not in $SORA_DIST"
	else
		fetch "$repo/releases/download/v$version/$name" "$work/$name" || die "could not download $name"
	fi
done

(
	cd "$work"
	for name in $files; do
		grep -E "  \\*?$name\$" SHA256SUMS >>expected || die "$name is not in SHA256SUMS"
	done
	sha256sum -c --quiet expected || die "a download does not match SHA256SUMS; nothing was installed"
)

set --
for name in $files; do
	set -- "$@" "$work/$name"
done
case "$manager" in
apt) $as_root apt-get install -y "$@" ;;
dnf) $as_root dnf install -y "$@" ;;
zypper) $as_root zypper --non-interactive install --allow-unsigned-rpm "$@" ;;
pacman) $as_root pacman -U --noconfirm --needed "$@" ;;
esac

say "sora: installed. The core runs as the sora-core service; open Sora from the applications menu."
