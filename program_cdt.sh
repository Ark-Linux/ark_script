#! /bin/bash

PROJECT_DIR=$(readlink -f $(pwd)/..)
CRTDIR=$(pwd)

readonly CDT_FOLDER="cdt-image"

readonly PROJECT_INFO=( \
	evk_405_cdt		0x03,0x20,0x02,0x00,0x01,0x00,end \
	ninja_405_cdt		0x03,0x20,0x66,0x00,0x00,0x00,end \
	ninja_403_cdt		0x03,0x20,0x55,0x00,0x00,0x00,end \
	zepp_evt_cdt   		0x03,0x20,0x55,0x01,0x04,0x00,end \
	md_p15_es_cdt  		0x03,0x20,0x15,0x01,0x00,0x00,end \
        tym_lv_es_cdt           0x03,0x20,0x15,0x01,0x01,0x00,end \
        tym_r1_es_cdt           0x03,0x20,0x01,0x01,0x00,0x00,end \
	gen_all_cdt		" " \
	clean_all_cdt		" " \
	Quit			" " \
)

die() { echo $* >&2; exit 1; }
USAGE() {
cat <<-EOF
Usage:
Program CDT

$(basename $0) [-i INTERACTIVE]
* -i/--interactive: interactive option either n(non-interactive) or y(interactive).
* -c/--clean: clean all CDT

example:
./$(basename $0) -i n
./$(basename $0) -i y
./$(basename $0) -c

EOF
	exit 1
}

generate_gpt() {
	echo "generate gpt start"
	mkdir -p $CRTDIR/${CDT_FOLDER}/${1}/temp
	cp $PROJECT_DIR/BOOT.XF.0.1/boot_images/QcomPkg/Tools/emmc_cdt_program_scripts/partition.xml $CRTDIR/${CDT_FOLDER}/${1}/temp/
	cp $PROJECT_DIR/QCS405.LE.1.2/common/config/storage/ptool.py $CRTDIR/${CDT_FOLDER}/${1}/temp/

	cd $CRTDIR/${CDT_FOLDER}/${1}/temp/
	python ptool.py -x partition.xml -gpt 2

	cp ./gpt_main2.bin ../
	cp ./gpt_backup2.bin ../
	cp ./patch2.xml ../

	cd ../
	rm -rf temp
	cd $CRTDIR
	echo "generate gpt finish"
}

generate_rawprogram() {
	echo "generate rawprogram start"

	echo "<?xml version=\"1.0\" ?>
<data>
  <!--NOTE: This is an ** Autogenerated file **-->
  <!--NOTE: Sector size is 512bytes-->
  <program SECTOR_SIZE_IN_BYTES=\"512\" file_sector_offset=\"0\" filename=\"${1}.bin\" label=\"CDT\" num_partition_sectors=\"4\" partofsingleimage=\"false\" physical_partition_number=\"2\" readbackverify=\"false\" size_in_KB=\"2.0\" sparse=\"false\" start_byte_hex=\"0x4400\" start_sector=\"34\"/>
  <program SECTOR_SIZE_IN_BYTES=\"512\" file_sector_offset=\"0\" filename=\"\" label=\"last_grow\" num_partition_sectors=\"1\" partofsingleimage=\"false\" physical_partition_number=\"2\" readbackverify=\"false\" size_in_KB=\"0.5\" sparse=\"false\" start_byte_hex=\"0x4c00\" start_sector=\"38\"/>
  <program SECTOR_SIZE_IN_BYTES=\"512\" file_sector_offset=\"0\" filename=\"gpt_main2.bin\" label=\"PrimaryGPT\" num_partition_sectors=\"34\" partofsingleimage=\"true\" physical_partition_number=\"2\" readbackverify=\"false\" size_in_KB=\"17.0\" sparse=\"false\" start_byte_hex=\"0x0\" start_sector=\"0\"/>
  <program SECTOR_SIZE_IN_BYTES=\"512\" file_sector_offset=\"0\" filename=\"gpt_backup2.bin\" label=\"BackupGPT\" num_partition_sectors=\"33\" partofsingleimage=\"true\" physical_partition_number=\"2\" readbackverify=\"false\" size_in_KB=\"16.5\" sparse=\"false\" start_byte_hex=\"(512*NUM_DISK_SECTORS)-16896.\" start_sector=\"NUM_DISK_SECTORS-33.\"/>
</data>" > $CRTDIR/${CDT_FOLDER}/${1}/rawprogram2.xml

	echo "generate rawprogram finish"
}

copy_programmer_elf() {
	echo "copy programmer elf start"

	cp $PROJECT_DIR/BOOT.XF.0.1/boot_images/QcomPkg/Qcs405Pkg/Bin/405/LA/RELEASE/prog_firehose_ddr.elf $CRTDIR/${CDT_FOLDER}/${1}/

	echo "copy progtammer elf finish"
}

generate_cdt_bin() {
	echo "generate cdt bin start"

	mkdir -p $CRTDIR/${CDT_FOLDER}/${1}/temp
	cp $PROJECT_DIR/BOOT.XF.0.1/boot_images/QcomPkg/Tools/cdt_generator.py $CRTDIR/${CDT_FOLDER}/${1}/temp
	cp $PROJECT_DIR/BOOT.XF.0.1/boot_images/QcomPkg/Tools/iot_0.0_platform_dal_jedec_lpddr3_single_channel_dal.xml $CRTDIR/${CDT_FOLDER}/${1}/temp

	cd $CRTDIR/${CDT_FOLDER}/${1}/temp

	#Modify xml
	sed -i '/platform_id/{n;d}' iot_0.0_platform_dal_jedec_lpddr3_single_channel_dal.xml
	sed -i "/platform_id/ a\\$2" iot_0.0_platform_dal_jedec_lpddr3_single_channel_dal.xml

	python cdt_generator.py iot_0.0_platform_dal_jedec_lpddr3_single_channel_dal.xml ${1}.bin

	cp ${1}.bin ../
	cd ../
	rm -rf temp
	cd $CRTDIR

	echo "generate cdt bin finish"
}

gen_specified_cdt() {
	echo "generate specified cdt | project: ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]} ID: ${PROJECT_INFO[$(expr ${1} \* 2 + 1)]}"

	generate_gpt ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}
	generate_rawprogram ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}
	copy_programmer_elf ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}
	generate_cdt_bin ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]} ${PROJECT_INFO[$(expr ${1} \* 2 + 1)]}
}

zip_specified_cdt() {
	cd $CRTDIR/${CDT_FOLDER}

	zip -p -r ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}.zip ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}
	md5sum ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}.zip > ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}.zip.md5

	MD5_CONTENT=$(cat ./${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}.zip.md5)
	eval `echo ${MD5_CONTENT}|awk -F " ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}" '{print "md5_num="$1}'`
	MD5_NUMBER=${md5_num}

	DATE=$(date +%Y-%m-%d)

	mv ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}.zip ${PROJECT_INFO[$(expr ${1} \* 2 + 0)]}_${DATE}_${MD5_NUMBER}.zip
	
}

clean_all_cdt() {
	cd $CRTDIR
	rm -rf ${CDT_FOLDER}*
}

gen_all_cdt() {
	clean_all_cdt

	for((list=0; list<$(expr ${#PROJECT_INFO[*]} / 2 - 3); list++))
	do
		gen_specified_cdt ${list}
	done

	cd $CRTDIR

	zip -p -r ${CDT_FOLDER}.zip ${CDT_FOLDER}
	md5sum ${CDT_FOLDER}.zip > ${CDT_FOLDER}.zip.md5

	MD5_CONTENT=$(cat ./${CDT_FOLDER}.zip.md5)
	eval `echo ${MD5_CONTENT}|awk -F ' c' '{print "md5_num="$1}'`
	MD5_NUMBER=${md5_num}

	DATE=$(date +%Y-%m-%d)
	
	mkdir -p $CRTDIR/build
	mv ${CDT_FOLDER}.zip $CRTDIR/build/${CDT_FOLDER}_${DATE}_${MD5_NUMBER}.zip
	
}

#clean_all_cdt() {
#	cd $CRTDIR
#	rm -rf ${CDT_FOLDER}*
#}

show_list() {
	echo "    --generate cdt--    "
	for((list=0; list<$(expr ${#PROJECT_INFO[*]} / 2); list++))
	do
		PROJECT_NAME=${PROJECT_INFO[$(expr $list \* 2 + 0)]}
		echo "    $[list+1]. $PROJECT_NAME"
	done
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		-i|--interactive)
			if [[ $2 == "y" ]] || [[ $2 == "n" ]]; then
				INTERACTIVE=$2
			fi
			shift 2
			;;
		-c|--clean)
			CLEAN=$1
			shift 1
			;;
		*)
			echo "Unknown option $1"
            USAGE
			exit 1;;
		esac
done

if [[ ${CLEAN} == "" ]] && [[ ${INTERACTIVE} == "" ]]; then
    echo "ERROR: function option ERROR"
    USAGE
fi

if [ ! -d $CRTDIR/${CDT_FOLDER} ];then
	mkdir -p $CRTDIR/${CDT_FOLDER}
fi

if [[ ${CLEAN} == "--clean" ]] || [[ ${CLEAN} == "-c" ]]; then
	clear
	clean_all_cdt
elif [[ ${INTERACTIVE} == "n" ]]; then
	clear
	gen_all_cdt
else
	clear
	while :
	do
		show_list
		read -p "Enter Number:" project_num
		if [[ ${project_num} -lt $(expr ${#PROJECT_INFO[*]} / 2 + 1) ]] && [[ 0 -lt ${project_num} ]]; then
			if [[ ${project_num} == $(expr ${#PROJECT_INFO[*]} / 2) ]]; then
				exit
			elif [[ ${project_num} == $(expr ${#PROJECT_INFO[*]} / 2 - 1) ]]; then
				clean_all_cdt
			elif [[ ${project_num} == $(expr ${#PROJECT_INFO[*]} / 2 - 2) ]]; then
				gen_all_cdt
			else
				gen_specified_cdt $[${project_num} - 1]
				zip_specified_cdt $[${project_num} - 1]
			fi
		else
			project_num=0;
		fi
	done
fi
clean_all_cdt
