#! /bin/bash

PROJECT_DIR=$(readlink -f $(pwd)/..)
CRTDIR=$(pwd)

readonly CDT_FOLDER="cdt-image"

readonly PROJECT_EVK405="evk_405_cdt"
readonly PROJECT_SBAR="sbar_cdt"
readonly PROJECT_ZEPP="zepp_cdt"

readonly EVK403_PLATFORM_ID="0x03,0x20,0x01,0x00,0x04,0x00,end"
readonly EVK405_PLATFORM_ID="0x03,0x20,0x02,0x00,0x01,0x00,end"
readonly SBAR_PLATFORM_ID="0x03,0x20,0x66,0x00,0x00,0x00,end"
readonly ZEPP_PLATFORM_ID="0x03,0x20,0x55,0x00,0x00,0x00,end"

if [ ! -d $PROJECT_DIR/${CDT_FOLDER} ];then
	mkdir -p $PROJECT_DIR/${CDT_FOLDER}
fi

generate_gpt() {
	mkdir -p $PROJECT_DIR/${CDT_FOLDER}/${1}/temp
	cp $PROJECT_DIR/boot_images/QcomPkg/Tools/emmc_cdt_program_scripts/partition.xml $PROJECT_DIR/${CDT_FOLDER}/${1}/temp/
	cp $PROJECT_DIR/common/config/storage/ptool.py $PROJECT_DIR/${CDT_FOLDER}/${1}/temp/

	cd $PROJECT_DIR/${CDT_FOLDER}/${1}/temp/
	python ptool.py -x partition.xml -gpt 2

	cp ./gpt_main2.bin ../
	cp ./gpt_backup2.bin ../
	cp ./patch2.xml ../

	cd ../
	rm -rf temp
	cd $CRTDIR
}

generate_rawprogram() {
	echo "<?xml version=\"1.0\" ?>
<data>
  <!--NOTE: This is an ** Autogenerated file **-->
  <!--NOTE: Sector size is 512bytes-->
  <program SECTOR_SIZE_IN_BYTES=\"512\" file_sector_offset=\"0\" filename=\"${1}.bin\" label=\"CDT\" num_partition_sectors=\"4\" partofsingleimage=\"false\" physical_partition_number=\"2\" readbackverify=\"false\" size_in_KB=\"2.0\" sparse=\"false\" start_byte_hex=\"0x4400\" start_sector=\"34\"/>
  <program SECTOR_SIZE_IN_BYTES=\"512\" file_sector_offset=\"0\" filename=\"\" label=\"last_grow\" num_partition_sectors=\"1\" partofsingleimage=\"false\" physical_partition_number=\"2\" readbackverify=\"false\" size_in_KB=\"0.5\" sparse=\"false\" start_byte_hex=\"0x4c00\" start_sector=\"38\"/>
  <program SECTOR_SIZE_IN_BYTES=\"512\" file_sector_offset=\"0\" filename=\"gpt_main2.bin\" label=\"PrimaryGPT\" num_partition_sectors=\"34\" partofsingleimage=\"true\" physical_partition_number=\"2\" readbackverify=\"false\" size_in_KB=\"17.0\" sparse=\"false\" start_byte_hex=\"0x0\" start_sector=\"0\"/>
  <program SECTOR_SIZE_IN_BYTES=\"512\" file_sector_offset=\"0\" filename=\"gpt_backup2.bin\" label=\"BackupGPT\" num_partition_sectors=\"33\" partofsingleimage=\"true\" physical_partition_number=\"2\" readbackverify=\"false\" size_in_KB=\"16.5\" sparse=\"false\" start_byte_hex=\"(512*NUM_DISK_SECTORS)-16896.\" start_sector=\"NUM_DISK_SECTORS-33.\"/>
</data>" > $PROJECT_DIR/${CDT_FOLDER}/${1}/rawprogram2.xml
}

copy_programmer_elf() {
	cp $PROJECT_DIR/boot_images/QcomPkg/Qcs405Pkg/Bin/405/LA/RELEASE/prog_firehose_ddr.elf $PROJECT_DIR/${CDT_FOLDER}/${1}/
}

generate_cdt_bin() {
	mkdir -p $PROJECT_DIR/${CDT_FOLDER}/${1}/temp
	cp $PROJECT_DIR/boot_images/QcomPkg/Tools/cdt_generator.py $PROJECT_DIR/${CDT_FOLDER}/${1}/temp
	cp $PROJECT_DIR/boot_images/QcomPkg/Tools/iot_0.0_platform_dal_jedec_lpddr3_single_channel_dal.xml $PROJECT_DIR/${CDT_FOLDER}/${1}/temp

	cd $PROJECT_DIR/${CDT_FOLDER}/${1}/temp

	#Modify xml
	sed -i '/platform_id/{n;d}' iot_0.0_platform_dal_jedec_lpddr3_single_channel_dal.xml
	sed -i "/platform_id/ a\\$2" iot_0.0_platform_dal_jedec_lpddr3_single_channel_dal.xml

	python cdt_generator.py iot_0.0_platform_dal_jedec_lpddr3_single_channel_dal.xml ${1}.bin

	cp ${1}.bin ../
	cd ../
	rm -rf temp
	cd $CRTDIR
}

gen_evk_405_cdt() {
	generate_gpt ${PROJECT_EVK405}
	generate_rawprogram ${PROJECT_EVK405}
	copy_programmer_elf ${PROJECT_EVK405}
	generate_cdt_bin ${PROJECT_EVK405} ${EVK405_PLATFORM_ID}
}

gen_sbar_cdt() {
	generate_gpt ${PROJECT_SBAR}
	generate_rawprogram ${PROJECT_SBAR}
	copy_programmer_elf ${PROJECT_SBAR}
	generate_cdt_bin ${PROJECT_SBAR} ${SBAR_PLATFORM_ID}
}

gen_zepp_cdt() {
	generate_gpt ${PROJECT_ZEPP}
	generate_rawprogram ${PROJECT_ZEPP}
	copy_programmer_elf ${PROJECT_ZEPP}
	generate_cdt_bin ${PROJECT_ZEPP} ${ZEPP_PLATFORM_ID}
}

gen_all_cdt() {
	gen_evk_405_cdt
	gen_sbar_cdt
	gen_zepp_cdt

	cd $PROJECT_DIR

	if [ -f ${CDT_FOLDER}.zip ];then
		rm -rf ${CDT_FOLDER}.zip
	fi

	if [ -f ${CDT_FOLDER}.zip.md5 ];then
		rm -rf ${CDT_FOLDER}.zip.md5
	fi

	zip -p -r ${CDT_FOLDER}.zip ${CDT_FOLDER}
	md5sum ${CDT_FOLDER}.zip > ${CDT_FOLDER}.zip.md5

	MD5_CONTENT=$(cat ./${CDT_FOLDER}.zip.md5)
	eval `echo ${MD5_CONTENT}|awk -F ' c' '{print "md5_num="$1}'`
	MD5_NUMBER=${md5_num}

	DATE=$(date +%Y-%m-%d)

	mv ${CDT_FOLDER}.zip ${CDT_FOLDER}_${DATE}_${MD5_NUMBER}.zip
}

clean_all_cdt() {
	cd $PROJECT_DIR
	rm -rf ${CDT_FOLDER}*
}

if [[ ${1} == "auto_gen" ]]; then
	clear
	gen_all_cdt
elif [[ ${1} == "clean" ]]; then
	clear
	clean_all_cdt
else
	clear
	while :
	do
	echo "************************"
	echo "*   --generate cdt--   *"
	echo "*    1. evk_405_cdt    *"
	echo "*    2. sbar_cdt       *"
	echo "*    3. zepp_cdt       *"
	echo "*    4. gen_all_cdt    *"
	echo "*    5. clean_all_cdt  *"
	echo "*    6. Quit           *"
	echo "************************"
	read -p "Enter Number:" project_num
		case $project_num in
		1)
		gen_evk_405_cdt
		;;
		2)
		gen_sbar_cdt
		;;
		3)
		gen_zepp_cdt
		;;
		4)
		gen_all_cdt
		;;
		5)
		clean_all_cdt
		;;
		6)
		clear
		break
		esac
	done
fi

