#! /bin/bash

readonly BOOT_VERSION="BOOT.XF.0.1/"
readonly COMMON_VERSION="QCS405.LE.1.2/"
readonly RPM_VERSION="RPM.BF.1.9/"
readonly TZ_VERSION="TZ.XF.5.1.2/"
readonly APPS_VERSION="LE.UM.4.1.2/"

readonly PROJECT_DIR=$(readlink -f $(pwd)/..)
readonly CRTDIR=$(pwd)
readonly PKG_NAME="release_pkg"
readonly FASTBOOT_PKG_NAME="fastboot_package"
readonly FASTBOOT_SCRIPT="script"

die() { echo $* >&2; exit 1; }

# copy pre-built binaries from workspace path
ws_dir_pkgs_paths=(
    ${PROJECT_DIR}/${BOOT_VERSION}boot_images/QcomPkg/Qcs405Pkg/Bin/405/LA/RELEASE/xbl.elf
    ${PROJECT_DIR}/${BOOT_VERSION}boot_images/QcomPkg/Qcs405Pkg/Bin/405/LA/RELEASE/pmic.elf
    ${PROJECT_DIR}/${BOOT_VERSION}boot_images/QcomPkg/Tools/binaries/logfs_ufs_8mb.bin
    ${PROJECT_DIR}/${COMMON_VERSION}common/build/emmc/bin/BTFM.bin
    ${PROJECT_DIR}/${COMMON_VERSION}common/build/emmc/bin/asic/NON-HLOS.bin
    ${PROJECT_DIR}/${COMMON_VERSION}common/build/bin/asic/dspso.bin
    ${PROJECT_DIR}/${RPM_VERSION}rpm_proc/build/ms/bin/AAAAANAZR/rpm.mbn
    ${PROJECT_DIR}/${TZ_VERSION}trustzone_images/build/ms/bin/OAPAANAA/cmnlib.mbn
    ${PROJECT_DIR}/${TZ_VERSION}trustzone_images/build/ms/bin/OAPAANAA/cmnlib64.mbn
    ${PROJECT_DIR}/${TZ_VERSION}trustzone_images/build/ms/bin/OAPAANAA/devcfg.mbn
#   ${PROJECT_DIR}/${TZ_VERSION}trustzone_images/build/ms/bin/OAPAANAA/keymaster64.mbn
    ${PROJECT_DIR}/${TZ_VERSION}trustzone_images/build/ms/bin/OAPAANAA/tz.mbn
    ${PROJECT_DIR}/${TZ_VERSION}trustzone_images/build/ms/bin/OAPAANAA/uefi_sec.mbn
    ${PROJECT_DIR}/${TZ_VERSION}trustzone_images/build/ms/bin/OAPAANAA/storsec.mbn
)

# linky fun from built binaries
deploy_dir=${PROJECT_DIR}/${APPS_VERSION}apps_proc/poky/build/tmp-glibc/deploy/images/
deploy_dir_pkgs=(
    abl.elf
    boot.img
    persist.img
    system.img
    systemrw.img
    cache.img
    usrdata.img
)

rm -rf ${CRTDIR}/${FASTBOOT_PACK_NAME}/${PKG_NAME}*

for ws_pkg_path in ${ws_dir_pkgs_paths[@]}; do
    [[ -e ${ws_pkg_path} ]] || die "${ws_pkg_path} does not exist"
    [[ -e ${CRTDIR}/${FASTBOOT_PKG_NAME}/${PKG_NAME} ]] || mkdir -p ${CRTDIR}/${FASTBOOT_PKG_NAME}/${PKG_NAME}
    cp -Rf ${ws_pkg_path} ${CRTDIR}/${FASTBOOT_PKG_NAME}/${PKG_NAME}
done

for deploy_pkgs in ${deploy_dir_pkgs[@]}; do
    deploy_pkg_path=$(find ${deploy_dir} -name ${deploy_pkgs} | head -1)
    [[ -e ${deploy_pkg_path} ]] || die "${deploy_pkg_path} does not exist"
    [[ -e ${CRTDIR}/${FASTBOOT_PKG_NAME}/${PKG_NAME} ]] || mkdir -p ${CRTDIR}/${FASTBOOT_PKG_NAME}/${PKG_NAME}
    cp -Rf ${deploy_pkg_path} ${CRTDIR}/${FASTBOOT_PKG_NAME}/${PKG_NAME}
done

cp -Rf ${CRTDIR}/${FASTBOOT_SCRIPT}/* ${CRTDIR}/${FASTBOOT_PKG_NAME}
chmod 777 ${CRTDIR}/${FASTBOOT_PKG_NAME}/*

cd ${CRTDIR}
zip -p -r ${FASTBOOT_PKG_NAME}.zip ${FASTBOOT_PKG_NAME}
md5sum ${FASTBOOT_PKG_NAME}.zip > ${FASTBOOT_PKG_NAME}.zip.md5

MD5_CONTENT=$(cat ./${FASTBOOT_PKG_NAME}.zip.md5)
eval `echo ${MD5_CONTENT}|awk -F " ${FASTBOOT_PKG_NAME}" '{print "md5_num="$1}'`
MD5_NUMBER=${md5_num}

DATE=$(date +%Y-%m-%d)

mv ${FASTBOOT_PKG_NAME}.zip ${FASTBOOT_PKG_NAME}_${DATE}_${MD5_NUMBER}.zip
