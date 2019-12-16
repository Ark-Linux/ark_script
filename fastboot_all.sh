#! /bin/sh

set -eo pipefail

readonly CRTDIR=$(pwd)
readonly PKG_NAME="release_pkg"

die() { echo $* >&2; exec bash; }
USAGE() {
cat <<-EOF
Usage:
Fastboot flash a qcs40x

$(basename $0) [-d SIDE] [-o EXTRA_FASTBOOT_FLASH_OPTIONS]
* -b/--boot: boot partition either a or b.
* -e/--environment: download environment either l(linux) or w(windows).
* -o/--option: (OPTIONAL) space seperated string of fastboot flash arguments. 
  
example:
./$(basename $0) -b a -e l
./$(basename $0) -b a -e l -o "--skip-reboot"

EOF
    exec bash;
#    exit 1
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
        -e|--environment)
            ENVIRONMENT=$2
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

if [[ ! "${ENVIRONMENT}" =~ ^((l)|(w))$ ]]; then
    echo "ERROR: download environment is not l(linux) or w(windows)"
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

set -x

for image in ${image_list[@]}; do
    image_path=$(find ${CRTDIR} -name ${image} | head -1)
    [[ -e ${image_path} ]] || die "${image} does not exist"
done

COMMAND=`adb devices`

if [[ -z $(echo ${COMMAND} | grep -w "device" | sed 's/.*attached //g;s/ device.*//g') ]]; then
    die "ERROR: list of devices is NULL"
    exit
fi

echo $(echo ${COMMAND} | grep -w "device" | sed 's/.*attached //g;s/ device.*//g')

#enter fastboot mode
adb reboot bootloader

if [[ ${ENVIRONMENT} == "l" ]]; then
    PERMISSIONS="sudo"
    EXECUTABLE_PROGRAM=""
else
    PERMISSIONS=""
    EXECUTABLE_PROGRAM=".exe"
fi

${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} devices

${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash bluetooth_${BOOT} ${PKG_NAME}/BTFM.bin
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash cmnlib64_${BOOT} ${PKG_NAME}/cmnlib64.mbn
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash cmnlib_${BOOT} ${PKG_NAME}/cmnlib.mbn
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash devcfg_${BOOT} ${PKG_NAME}/devcfg.mbn
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash dsp_${BOOT} ${PKG_NAME}/dspso.bin
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash keymaster_${BOOT} ${PKG_NAME}/keymaster64.mbn
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash logfs ${PKG_NAME}/logfs_ufs_8mb.bin
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash modem_${BOOT} ${PKG_NAME}/NON-HLOS.bin
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash pmic_${BOOT} ${PKG_NAME}/pmic.elf
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash rpm_${BOOT} ${PKG_NAME}/rpm.mbn
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash storsec ${PKG_NAME}/storsec.mbn
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash tz_${BOOT} ${PKG_NAME}/tz.mbn
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash uefisecapp_${BOOT} ${PKG_NAME}/uefi_sec.mbn
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash xbl_${BOOT} ${PKG_NAME}/xbl.elf

${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash abl_${BOOT} ${PKG_NAME}/abl.elf
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash boot_${BOOT}  ${PKG_NAME}/boot.img
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash persist ${PKG_NAME}/persist.img
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash system_${BOOT} ${PKG_NAME}/system.img
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash systemrw ${PKG_NAME}/systemrw.img
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash cache  ${PKG_NAME}/cache.img
${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} ${OPTION} flash userdata ${PKG_NAME}/usrdata.img

${PERMISSIONS} fastboot${EXECUTABLE_PROGRAM} reboot
exec bash;