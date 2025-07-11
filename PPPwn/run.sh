#!/bin/bash
VERSION=2.0
if [ -f /boot/firmware/PPPwn/config.sh ]; then
source /boot/firmware/PPPwn/config.sh
fi
if [ -z $INTERFACE ]; then INTERFACE="eth0"; fi
if [ -z $FIRMWAREVERSION ]; then FIRMWAREVERSION="11.00"; fi
if [ -z $SHUTDOWN ]; then SHUTDOWN=true; fi
if [ -z $PPPOECONN ]; then PPPOECONN=false; fi
if [ -z $VMUSB ]; then VMUSB=false; fi
if [ -z $PPDBG ]; then PPDBG=false; fi
if [ -z $TIMEOUT ]; then TIMEOUT="1m"; fi
WKYTYP=$(tr -d '\0' </proc/device-tree/model)
if [[ $WKYTYP == *"Xunlei OneCloud"* ]] ;then
    CPPBIN="pppwn_onecloud"
else
    echo -e "\033[91m Not OneCloud. Exit... \033[0m" | sudo tee /dev/tty1
    exit
fi
echo -e "\n\n\033[36m _____  _____  _____
|  __ \\|  __ \\|  __ \\
| |__) | |__) | |__) |_      ___ __
|  ___/|  ___/|  ___/\\ \\ /\\ / / '_ \\
| |    | |    | |     \\ V  V /| | | |
|_|    |_|    |_|      \\_/\\_/ |_| |_|\033[0m
\n\033[33mhttps://github.com/Mintneko/WKY-Pwn\033[0m\n" | sudo tee /dev/tty1
echo -e "\033[92mVersion $VERSION \033[0m" | sudo tee /dev/tty1
sudo systemctl stop pppoe >/dev/null 2>&1 &
if [ $VMUSB = true ] ; then
    echo "USB waiting....."
	coproc read -t 3 && wait "$!" || true
	sudo ip link set $INTERFACE up
   else
	sudo ip link set $INTERFACE down
	coproc read -t 5 && wait "$!" || true
	sudo ip link set $INTERFACE up
fi
echo -e "\n\033[36m$WKYTYP\033[92m\nFirmware:\033[93m $FIRMWAREVERSION\033[92m\nInterface:\033[93m $INTERFACE\033[0m" | sudo tee /dev/tty1
echo -e "\033[92mPPPwn:\033[93m C++ $CPPBIN \033[0m" | sudo tee /dev/tty1
if [ $VMUSB = true ] ; then
 sudo rmmod g_mass_storage
  FOUND=0
  readarray -t rdirarr  < <(sudo ls /media/pwndrives)
  for rdir in "${rdirarr[@]}"; do
    readarray -t pdirarr  < <(sudo ls /media/pwndrives/${rdir})
    for pdir in "${pdirarr[@]}"; do
       if [[ ${pdir,,}  == "payloads" ]] ; then
	     FOUND=1
	     UDEV='/dev/'${rdir}
	     break
      fi
    done
      if [ "$FOUND" -ne 0 ]; then
        break
      fi
  done
  if [[ ! -z $UDEV ]] ;then
    sudo modprobe g_mass_storage file=$UDEV stall=0 ro=0 removable=1
  fi
  echo -e "\033[92mUSB Drive:\033[93m Enabled\033[0m" | sudo tee /dev/tty1
fi
if [ $PPPOECONN = true ] ; then
   echo -e "\033[92mInternet Access:\033[93m Enabled\033[0m" | sudo tee /dev/tty1
else
   echo -e "\033[92mInternet Access:\033[93m Disabled\033[0m" | sudo tee /dev/tty1
fi
if [ -f /boot/firmware/PPPwn/pwn.log ]; then
   sudo rm -f /boot/firmware/PPPwn/pwn.log
fi
if [[ ! $(ethtool $INTERFACE) == *"Link detected: yes"* ]]; then
   echo -e "\033[31mWaiting for link\033[0m" | sudo tee /dev/tty1
   while [[ ! $(ethtool $INTERFACE) == *"Link detected: yes"* ]]
   do
      coproc read -t 2 && wait "$!" || true
   done
   echo -e "\033[32mLink found\033[0m\n" | sudo tee /dev/tty1
fi
WKYIP=$(hostname -I) || true
if [ "$WKYIP" ]; then
   echo -e "\n\033[92mIP: \033[93m $WKYIP\033[0m" | sudo tee /dev/tty1
fi
echo -e "\n\033[95mReady for console connection\033[0m\n" | sudo tee /dev/tty1
while [ true ]; do
   if [ -f /boot/firmware/PPPwn/config.sh ]; then
      if grep -Fxq "PPDBG=true" /boot/firmware/PPPwn/config.sh; then
         PPDBG=true
      else
         PPDBG=false
      fi
   fi
   if [[ $FIRMWAREVERSION == "10.00" ]]; then
      STAGEVER="10.00"
   elif [[ $FIRMWAREVERSION == "10.01" ]]; then
      STAGEVER="10.01"
   elif [[ $FIRMWAREVERSION == "10.50" ]]; then
      STAGEVER="10.50"
   elif [[ $FIRMWAREVERSION == "10.70" ]]; then
      STAGEVER="10.70"
   elif [[ $FIRMWAREVERSION == "10.71" ]]; then
      STAGEVER="10.71"
   elif [[ $FIRMWAREVERSION == "9.00" ]]; then
      STAGEVER="9.00"
   elif [[ $FIRMWAREVERSION == "9.03" ]] ;then
      STAGEVER="9.03"
   elif [[ $FIRMWAREVERSION == "9.60" ]]; then
      STAGEVER="9.60"
   else
      STAGEVER="11.00"
   fi
   while read -r stdo; do
      if [ $PPDBG = true ]; then
         echo -e $stdo | sudo tee /dev/tty1 | sudo tee /dev/pts/* | sudo tee -a /boot/firmware/PPPwn/pwn.log
      fi
      if [[ $stdo == "[+] Done.!" ]] || [[ $stdo == "0" ]]; then
         echo -e "\033[32m\nConsole PPPwned! \033[0m\n" | sudo tee /dev/tty1
         if [ $PPPOECONN = true ]; then
            sudo systemctl start pppoe /dev/null 2>&1 &
         else
            if [ $SHUTDOWN = true ]; then
               coproc read -t 5 && wait "$!" || true
               sudo poweroff
            else
               if [ $VMUSB = true ]; then
                  sudo systemctl start pppoe
               else
                  sudo ip link set $INTERFACE down
               fi
            fi
         fi
         exit 0
      elif [[ $stdo == *"Scanning for corrupted object...failed"* ]]; then
         echo -e "\033[31m\nFailed retrying...\033[0m\n" | sudo tee /dev/tty1
      elif [[ $stdo == *"Unsupported firmware version"* ]]; then
         echo -e "\033[31m\nUnsupported firmware version\033[0m\n" | sudo tee /dev/tty1
         exit 1
      elif [[ $stdo == *"Cannot find interface with name of"* ]]; then
         echo -e "\033[31m\nInterface $INTERFACE not found\033[0m\n" | sudo tee /dev/tty1
         exit 1
      fi
   done < <(timeout $TIMEOUT sudo /boot/firmware/PPPwn/$CPPBIN --interface "$INTERFACE" --fw "${STAGEVER//./}" --stage1 "/boot/firmware/PPPwn/stage1_$STAGEVER.bin" --stage2 "/boot/firmware/PPPwn/stage2_$STAGEVER.bin"; echo $?)
   coproc read -t 1 && wait "$!" || true
done
