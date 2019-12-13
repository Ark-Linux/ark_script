#! /bin/bash

set -eo pipefail

readonly CRTDIR=$(pwd)
readonly PKG_NAME="release_pkg"

die() { echo $* >&2; exit 1; }
USAGE() {
cat <<-EOF
Usage:
Fastboot flash a qcs40x

$(basename $0) [-d SIDE] [-o EXTRA_FASTBOOT_FLASH_OPTIONS]
* -b/--boot: (OPTIONAL) boot partition either a or b.
* -o/--option: (OPTIONAL) space seperated string of fastboot flash arguments. 
  
example:
./$(basename $0) -b a
./$(basename $0) -b a -o "--skip-reboot"
 
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--boot)
            BOOT=$(echo $2 | tr '[:upper:]' '[:lower:]')
            shift 2
            ;;
        -o|--option)
            OPTION=$2
            shift 2
            ;;
        *)
            echo "Unknown option $1"
            USAGE
            exit 1;;
        esac
done

if [[ ! "${BOOT}" =~ ^((a)|(b))$ ]]; then
    echo "ERROR: boot (${BOOT}) partition is not a or b"
    USAGE
fi

image_list=(
    xbl.elf
    pmic.elf
    logfs_ufs_8mb.bin
    BTFM.bin
    NON-HLOS.bin
    dspso.bin
    rpm.mbn
    cmnlib.mbn
    cmnlib64.mbn
    devcfg.mbn
    keymaster64.mbn
    tz.mbn
    uefi_sec.mbn
    storsec.mbn
    abl.elf
    boot.img
    persist.img
    system.img
    systemrw.img
    cache.img
    usrdata.img   
)



for image in ${image_list[@]}; do
    image_path=$(find ${CRTDIR} -name ${image} | head -1)
    [[ -e ${image_path} ]] || die "${image_path} does not exist"
done

set -x

COMMAND=`adb devices`
#echo 'List of devices attached 7aee2f0 device' | sed 's/.*attached //g;s/ device.*//g'

ADB_DEV_NUM=$(echo $COMMAND | grep -w "device" | sed 's/.*attached //g;s/ device.*//g')

[[ -n ${ADB_DEV_NUM} ]] || die "ERROR: list of devices is NULL"
echo $ADB_DEV_NUM

#enter fastboot mode
adb reboot bootloader
sudo fastboot devices

sudo fastboot ${OPTION} flash bluetooth_${BOOT} ${PKG_NAME}/BTFM.bin
sudo fastboot ${OPTION} flash cmnlib64_${BOOT} ${PKG_NAME}/cmnlib64.mbn
sudo fastboot ${OPTION} flash cmnlib_${BOOT} ${PKG_NAME}/cmnlib.mbn
sudo fastboot ${OPTION} flash devcfg_${BOOT} ${PKG_NAME}/devcfg.mbn
sudo fastboot ${OPTION} flash dsp_${BOOT} ${PKG_NAME}/dspso.bin
sudo fastboot ${OPTION} flash keymaster_${BOOT} ${PKG_NAME}/keymaster64.mbn
sudo fastboot ${OPTION} flash logfs ${PKG_NAME}/logfs_ufs_8mb.bin
sudo fastboot ${OPTION} flash modem_${BOOT} ${PKG_NAME}/NON-HLOS.bin
sudo fastboot ${OPTION} flash pmic_${BOOT} ${PKG_NAME}/pmic.elf
sudo fastboot ${OPTION} flash rpm_${BOOT} ${PKG_NAME}/rpm.mbn
sudo fastboot ${OPTION} flash storsec ${PKG_NAME}/storsec.mbn
sudo fastboot ${OPTION} flash tz_${BOOT} ${PKG_NAME}/tz.mbn
sudo fastboot ${OPTION} flash uefisecapp_${BOOT} ${PKG_NAME}/uefi_sec.mbn
sudo fastboot ${OPTION} flash xbl_${BOOT} ${PKG_NAME}/xbl.elf

sudo fastboot ${OPTION} flash abl_${BOOT} ${PKG_NAME}/abl.elf
sudo fastboot ${OPTION} flash boot_${BOOT}  ${PKG_NAME}/boot.img
sudo fastboot ${OPTION} flash persist ${PKG_NAME}/persist.img
sudo fastboot ${OPTION} flash system_${BOOT} ${PKG_NAME}/system.img
sudo fastboot ${OPTION} flash systemrw ${PKG_NAME}/systemrw.img
sudo fastboot ${OPTION} flash cache  ${PKG_NAME}/cache.img
sudo fastboot ${OPTION} flash userdata ${PKG_NAME}/usrdata.img

sudo fastboot reboot