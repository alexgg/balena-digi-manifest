#!/bin/bash
#===============================================================================
#
#  build.sh
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License version 2 as published by
#  the Free Software Foundation.
#
#
#  !Description: Balena autobuild script from Jenkins.
#
#  Parameters set by Jenkins:
#     WORKSPACE: Working directory
#     REVISION:  Revision of the manifest repository (for 'repo init')
#
#===============================================================================

set -e

MANIFEST_URL="https://github.com/alexgg/balena-digi-manifest.git"

REPO="$(which repo)"

error() {
	printf "${1}"
	exit 1
}

#
# Copy buildresults (images, licenses, packages)
#
#  $1: destination directoy
#
copy_images() {
	# Copy individual packages only for 'release' builds, not for 'daily'.
	# For 'daily' builds just copy the firmware images (the buildserver
	# cannot afford such amount of disk space)
	if echo ${JOB_NAME} | grep -qs 'balena-digi.*release'; then
		cp -r build/tmp/deploy/* ${1}/
	else
		cp -r build/tmp/deploy/images ${1}/
	fi

	# Images directory post-processing
	#  - Jenkins artifact archiver does not copy symlinks, so remove them
	#    beforehand to avoid ending up with several duplicates of the same
	#    files.
	#  - Remove 'README_-_DO_NOT_DELETE_FILES_IN_THIS_DIRECTORY.txt' files
	#  - Create MD5SUMS file
	find ${1} -type l -delete
	find ${1} -type f -name 'README_-_DO_NOT_DELETE*' -delete
	find ${1} -type f -not -name MD5SUMS -print0 | xargs -r -0 md5sum | sed -e "s,${1}/,,g" | sort -k2,2 > ${1}/MD5SUMS
}

# Sanity checks (Jenkins environment)
[ -z "${REVISION}" ] && error "REVISION not specified"
[ -z "${WORKSPACE}" ] && error "WORKSPACE not specified"

YOCTO_IMGS_DIR="${WORKSPACE}/images"
YOCTO_INST_DIR="${WORKSPACE}/balena-digi.$(echo ${REVISION} | tr '/' '_')"

CPUS="$(grep -c processor /proc/cpuinfo)"
[ ${CPUS} -gt 1 ] && MAKE_JOBS="-j${CPUS}"

printf "\n[INFO] Build Yocto \"${REVISION}\" (cpus=${CPUS})\n\n"

# Install balena-digi
rm -rf ${YOCTO_INST_DIR} && mkdir -p ${YOCTO_INST_DIR}
if pushd ${YOCTO_INST_DIR}; then
	# Use git ls-remote to check the revision type
	if [ "${REVISION}" != "master" ]; then
		if git ls-remote --tags --exit-code "${MANIFEST_URL}" "${REVISION}"; then
			printf "[INFO] Using tag \"${REVISION}\"\n"
			repo_revision="-b refs/tags/${REVISION}"
		elif git ls-remote --heads --exit-code "${MANIFEST_URL}" "${REVISION}"; then
			printf "[INFO] Using branch \"${REVISION}\"\n"
			repo_revision="-b ${REVISION}"
		else
			error "Revision \"${REVISION}\" not found"
		fi
	fi
	yes "" 2>/dev/null | ${REPO} init --no-repo-verify -u ${MANIFEST_URL} ${repo_revision}
	${REPO} forall -p -c 'git remote prune $(git remote)'
	time ${REPO} sync -d ${MAKE_JOBS}
	popd
fi

BARYS_OPTIONS="--rm-work"

# Create projects and build
rm -rf ${YOCTO_IMGS_DIR}
if pushd ${YOCTO_INST_DIR}; then
	# Configure and build the project in a sub-shell to avoid
	# mixing environments
	(
		time ./balena-yocto-scripts/build/barys ${BARYS_OPTIONS}
	)
	copy_images ${YOCTO_IMGS_DIR}/${platform}
	popd
fi

