#! /bin/bash

PROJECT_DIR=$(readlink -f $(pwd)/..)
CRTDIR=$(pwd)

copy_Non_HLOS_file() {
	cd $PROJECT_DIR/apps_proc/poky/build/tmp-glibc/work/x86_64-linux/releasetools-native/1.0-r0/releasetools
	echo $(pwd)

	rm -rf ./temp
	mkdir temp
	cp target-files-ext4.zip ./temp
	cd ./temp
	unzip target-files-ext4.zip
	rm -rf target-files-ext4.zip
	echo "target file unzip finish\n"

	cp -Rf $PROJECT_DIR/rpm_proc/build/ms/bin/AAAAANAZR/rpm.mbn ./RADIO
	cp -Rf $PROJECT_DIR/common/build/emmc/bin/asic/NON-HLOS.bin ./RADIO
	cp -Rf $PROJECT_DIR/common/build/bin/asic/dspso.bin ./RADIO
	cp -Rf $PROJECT_DIR/boot_images/QcomPkg/Qcs405Pkg/Bin/405/LA/RELEASE/xbl.elf ./RADIO
	cp -Rf $PROJECT_DIR/boot_images/QcomPkg/Qcs405Pkg/Bin/405/LA/RELEASE/pmic.elf ./RADIO
	cp -Rf $PROJECT_DIR/boot_images/QcomPkg/Tools/binaries/logfs_ufs_8mb.bin ./RADIO
	cp -Rf $PROJECT_DIR/trustzone_images/build/ms/bin/OAPAANAA/keymaster64.mbn ./RADIO
	cp -Rf $PROJECT_DIR/trustzone_images/build/ms/bin/OAPAANAA/storsec.mbn ./RADIO
	cp -Rf $PROJECT_DIR/trustzone_images/build/ms/bin/OAPAANAA/tz.mbn ./RADIO
	cp -Rf $PROJECT_DIR/trustzone_images/build/ms/bin/OAPAANAA/uefi_sec.mbn ./RADIO
	echo "copy Non HLOS image finish\n"

	zip -p -r target-files-ext4.zip ./*
	rm -rf ../target-files-ext4.zip
	mv target-files-ext4.zip ../
	cd ../
	rm -rf temp
	echo "gen target file finish\n"

	./full_ota.sh target-files-ext4.zip ../../../../vt_64-oe-linux/machine-image/1.0-r0/rootfs ext4 --block
	echo "gen otg package finish\n"
}

generate_ota_file() {
	if [[ ! -d $PROJECT_DIR/ota_proc ]];then
		mkdir -p $PROJECT_DIR/ota_proc
	fi

	cp -rf $PROJECT_DIR/apps_proc/poky/build/tmp-glibc/work/x86_64-linux/releasetools-native/1.0-r0/releasetools/update_ext4.zip $PROJECT_DIR/ota_proc

	cd $PROJECT_DIR/ota_proc

	md5sum update_ext4.zip > update_ext4.zip.md5

	MD5_CONTENT=$(cat ./update_ext4.zip.md5)
	eval `echo ${MD5_CONTENT}|awk -F ' u' '{print "md5_num="$1}'`
	MD5_NUMBER=${md5_num}

	DATE=$(date +%Y-%m-%d)

	mv update_ext4.zip.md5 update_ext4_${DATE}.zip.md5
	mv update_ext4.zip update_ext4_${DATE}_${MD5_NUMBER}.zip
}

clean_ota_file() {
	cd $PROJECT_DIR/ota_proc
	rm -rf ./*
}

if [[ ${1} == "clean" ]]; then
	clear
	clean_ota_file
else
	clear
	copy_Non_HLOS_file
	generate_ota_file
fi
