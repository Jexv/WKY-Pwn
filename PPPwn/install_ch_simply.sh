#!/bin/bash
echo '"ppp"  *  "ppp"  192.168.233.2' | sudo tee /etc/ppp/pap-secrets
while true; do
read -p "$(printf '\r\n\r\n\033[36m是否要更改正在使用的PS4固件版本，默认值为 11.00\r\n\r\n\033[36m(Y|N)?: \033[0m')" fwset
case $fwset in
[Yy]* ) 
while true; do
read -p  "$(printf '\033[33m输入固件版本 [11.00 | 10.71 | 10.70 | 10.50 | 10.01 | 10.00 | 9.60 | 9.00]: \033[0m')" FWV
case $FWV in
"" ) 
 echo -e '\033[31m不 能 为 空 !\033[0m';;
 * )  
if grep -q '^[0-9.]*$' <<<$FWV ; then 

if [[ ! "$FWV" =~ ^("11.00"|"10.71"|"10.70"|"10.50"|"10.01"|"10.00"|"9.60"|"9.00")$ ]]  ; then
echo -e '\033[31mT版本必须为11.00, 10.71, 10.70, 10.50, 10.01, 10.00, 9.60 或 9.00\033[0m';
else 
break;
fi
else 
echo -e '\033[31m版本只能包含字母数字字符\033[0m';
fi
esac
done
echo -e '\033[32m您正在使用 '$FWV'\033[0m'
break;;
[Nn]* ) 
echo -e '\033[35m使用默认设置: 11.00\033[0m'
FWV="11.00"
break;;
* ) echo -e '\033[31m请输入 Y 或 N\033[0m';;
esac
done
echo '#!/bin/bash
INTERFACE="eth0" 
FIRMWAREVERSION="'$FWV'" 
SHUTDOWN=true
USECPP=true
PPPOECONN=false
DTLINK=false
PPDBG=false
TIMEOUT="1m"
VMUSB=false'  | sudo tee /boot/firmware/PPPwn/config.sh >/dev/null 2>&1 &
sudo rm /usr/lib/systemd/system/bluetooth.target >/dev/null 2>&1 &
sudo rm /usr/lib/systemd/system/network-online.target >/dev/null 2>&1 &
sudo sed -i 's^sudo bash /boot/firmware/PPPwn/run.sh \&^^g' /etc/rc.local
echo '[Service]
WorkingDirectory=/boot/firmware/PPPwn
ExecStart=/boot/firmware/PPPwn/run.sh
Restart=never
User=root
Group=root
Environment=NODE_ENV=production
[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/wkypwn.service >/dev/null 2>&1 &
sudo chmod u+rwx /etc/systemd/system/wkypwn.service
sudo systemctl enable wkypwn
sudo systemctl start wkypwn
echo -e '\033[36m安装完成,\033[33m 正在重启中······\033[0m'
sudo reboot
