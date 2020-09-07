#! /usr/bin/python
# -*- coding: UTF-8 -*-

import os
import platform
import subprocess
import threading
import time


class FastbootImage:
    __current_dir = "./"  # os.getcwd()
    __timeout = [False, 23]
    __packge_name = "release_pkg"
    __system_environment = "Linux"
    __check_fastboot_command = ""
    __platform_command = ""
    __image_table = (('xbl.elf', 'xbl_a'), ('pmic.elf', 'pmic_a'), ('logfs_ufs_8mb.bin', 'logfs'), \
                     ('BTFM.bin', 'bluetooth_a'), ('NON-HLOS.bin', 'modem_a'), ('dspso.bin', 'dsp_a'), \
                     ('rpm.mbn', 'rpm_a'), ('cmnlib.mbn', 'cmnlib_a'), ('cmnlib64.mbn', 'cmnlib64_a'), \
                     ('devcfg.mbn', 'devcfg_a'), ('keymasterapp.mbn', 'keymaster_a'), ('tz.mbn', 'tz_a'), \
                     ('uefi_sec.mbn', 'uefisecapp_a'), ('storsec.mbn', 'storsec'), ('abl.elf', 'abl_a'), \
                     ('boot.img', 'boot_a'), ('persist.img', 'persist'), ('system.img', 'system_a'), \
                     ('systemrw.img', 'systemrw'), ('cache.img', 'cache'), ('usrdata.img', 'userdata'))

    def __check_image(self):
        check_result = True
        for image in self.__image_table:
            image_file = self.__current_dir + self.__packge_name + "/" + image[0]
            if os.path.exists(image_file) == False:
                print("Fail: The image is not exist:", image)
                check_result = False
        print("check image succeed")
        return check_result

    def __find_devices(self):
        device_info = []
        find_result = True
        print("find devices")
        devices_list = os.popen('adb devices').readlines()
        for i in range(len(devices_list)):
            if devices_list[i].find('\tdevice') != -1:
                device_info.append(devices_list[i].split('\t')[0])
        if len(device_info) <= 0:
            find_result = False
        else:
            print("Find devices ID:", device_info)
        return find_result

    def __check_environment(self):
        check_result = True
        if platform.system() == 'Linux':
            self.__system_environment = 'Linux'
            self.__check_fastboot_command = "sudo fastboot devices"
            self.__platform_command = "sudo fastboot "
        elif platform.system() == 'Windows':
            self.__system_environment = 'Windows'
            self.__check_fastboot_command = 'fastboot.exe devices'
            self.__platform_command = "fastboot.exe "
        else:
            check_result = False
        return check_result

    def __into_fastboot_mode(self):
        os.popen('adb reboot bootloader')
        while len(os.popen(self.__check_fastboot_command).readlines()) > 0:
            break

    def __fastboot_process(self):
        lock = threading.Lock()
        for image in self.__image_table:
            fastboot_command = self.__platform_command + 'flash ' + image[1] + ' ./' + self.__packge_name + '/' + image[0]
            lock.acquire()
            os.popen(fastboot_command)
            print("\ndownloading image: " + image[0] + " succeed")
            time.sleep(0.3)
            lock.release()
        if self.__system_environment is 'Windows':
            threading.Thread(target=self.__is_timeout, args=(int(self.__timeout[1]),)).start()
            while self.__timeout[0] is False:
                continue
            self.__timeout[0] = False
        print("\n--- system reboot ---\n")
        fastboot_command = self.__platform_command + "reboot"
        os.popen(fastboot_command)
        if self.__system_environment is 'Windows':
            time.sleep(7)
        print("\n--- Fastboot Succeed ---\n")

    def __is_timeout(self, timeout):
        while timeout > 0:
            timeout -= 1
            time.sleep(1)
        self.__timeout[0] = True

    def run(self):
        if self.__check_image() == True:
            if self.__find_devices() == True:
                if self.__check_environment() == True:
                    self.__into_fastboot_mode()
                    self.__fastboot_process()
                else:
                    print("Fail: The script does not support the current system!")
            else:
                print("Fail: No find devices!")
        else:
            print("Fail: Some image don't exist!")



if __name__ == '__main__':
    fastboot_image = FastbootImage()
    fastboot_image.run()

    # os.popen('adb reboot bootloader')
    # print(os.popen('fastboot.exe devices').readlines())
    # print(os.popen('adb devices').readlines())
    # print(os.popen("fastboot.exe flash abl_a ./release_pkg/abl.elf").readlines())

    # r = subprocess.Popen(['fastboot.exe', 'flash', 'abl_a', './release_pkg/abl.elf'], stdout=subprocess.PIPE).communicate()[0]
    # print(r)



