#!/bin/bash

# Higly inspired from kaz/archlinux-repository-boilerplate

ARCH=x86_64
MAKEFLAGS="-j$(nproc)"

: ${BUILD_USER:="builder"}

: ${PKGS_DIR=/tmp/__pkgs__}
: ${CCACHE_DIR:="/tmp/ccache"}

: ${GITHUB_ACTOR:=""}
: ${GIT_REMOTE:=""}
: ${GIT_BRANCH:="gh-pages"}

GITHUB_REPO_OWNER=${GITHUB_REPOSITORY%/*}
ARCH_REPO_NAME=heera

create_local() {
	mkdir -pv $PKGS_DIR/x86_64

	# Create the package database (Ignore warnings)
	repo-add $PKGS_DIR/x86_64/pkgs.db.tar.gz
}

update_local_repo() {
	repo-add "$PKGS_DIR"/pkgs.db.tar.gz "$PKGS_DIR/x86_64/"*.tar.gz
	pacman -Sy
}

initialize() {
	pacman -Syu --noconfirm --needed git wget ccache ninja

	echo "${BUILD_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${BUILD_USER}
	echo "cache_dir = ${CCACHE_DIR}" > /etc/ccache.conf

	useradd -m ${BUILD_USER}
	chown -R ${BUILD_USER}:${BUILD_USER} .
}

build() {
	export MAKEFLAGS="-j$(nproc)"

	mkdir -pv "${PKGS_DIR}"

	for PKGBUILD_PATH in $(find . -name "PKGBUILD"); do
		pkgbuild_dir=${PKGBUILD_PATH%PKGBUILD}
		cd "$pkgbuild_dir"
			sudo -u "${BUILD_USER}" makepkg -s --noconfirm --needed || true
		cd ..
	done

}

ci_build() {
	export MAKEFLAGS="-j$(nproc)"

	mkdir -pv "${PKGS_DIR}"

	for PKGBUILD_PATH in $(find . -name "PKGBUILD"); do
		pkgbuild_dir=${PKGBUILD_PATH%PKGBUILD}
		pushd "$pkgbuild_dir"
			sudo -u "${BUILD_USER}" makepkg -sfr --noconfirm --needed
			cp -v *.pkg.tar.zst "${PKGS_DIR}/x86_64/"
			update_local_repo
		popd
	done
}

publish() {
	# Expecting the branch is cloned at "${GITHUB_BRANCH}"
	cd "${GIT_BRANCH}"

	rm -rfv "${ARCH}"	# To remove older packages
	mkdir "${ARCH}"

	# Remove older commit
	git reset --soft HEAD^

	# Add the packages
	cd "${ARCH}"

	find "${PKGS_DIR}" -name "*.pkg.tar.zst" -exec cp -v "{}" . \;

	repo-add $ARCH_REPO_NAME.db.tar.gz *.pkg.tar.zst
	rename '.tar.gz' '' *.tar.gz

	# Commit
	git add --all --verbose
	git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
	git config user.name "${GITHUB_ACTOR}"

	git commit -m "Updated at $(date +'%d/%m/%Y %H:%M:%S')"

	# Push
	git push -fu origin "${GIT_BRANCH}"
}

set -xe
"$@"
