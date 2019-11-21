#! /bin/sh
MOUNT_STATUS=0
COUNT=0

echo 104 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio104/direction
echo 1 > /sys/class/gpio/gpio104/value

while :
do
	if [ -b "/dev/sda1" ]; then
		if [ ${MOUNT_STATUS} == 0 ]; then
			echo "usb disk detected"
	                mkdir -p /data/sda

			mount /dev/sda1 /data/sda
			MOUNT_STATUS=1
		fi

		if [ -f /data/sda/update_ext4*.zip ];then
			echo "usb disk have upgrade file"
			if [ -f /data/update_ext4*.zip ]; then
				rm -rf /data/update_ext4*.zip
			fi

			cp -Rf /data/sda/update_ext4*.zip /data

			mv /data/update_ext4*.zip /data/update_ext4.zip

			if [ -d "/cache/recovery" ]; then
				rm -rf /cache/recovery/*
			else
				mkdir -p /cache/recovery
			fi

			echo "--update_package=/data/update_ext4.zip" > /cache/recovery/command
			echo "upgrading ......"
			recovery
			echo "upgrade success!!!"
			echo 0 > /sys/class/gpio/gpio104/value
			break
		else
			if [ ${COUNT} -eq 0 ]; then
				echo "There are no upgrade file on the usb disk"
				COUNT=1
			fi
		fi
	else
		if [ -d "/data/sda" ]; then
			COUNT=0
			echo "usb disk remove"
			umount /data/sda
			MOUNT_STATUS=0
			rm -rf /data/sda
		fi
	fi
done
