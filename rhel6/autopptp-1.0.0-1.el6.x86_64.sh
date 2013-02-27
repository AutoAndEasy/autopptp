#!/bin/bash

################ Script Info ################		

## Program: This is use for PPTP VPN
## Author:chier xuefei
## Date: 2013-02-26
## Update:None


################ Env Define ################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:~/sbin
LANG=C
export PATH
export LANG

################ Var Setting ################

MyIP="1.2.3.4"
NatNet="192.168.194"
HomeDir="/tmp/autopptp/"
BasePkg="wget gcc ppp policycoreutils iptables"
SrcHost="https://raw.github.com"
SrcPath="/AutoAndEasy/autopptp/master/rhel6/"

################ Func Define ################ 
function _info_msg() {
_header
echo -e " |                                                                |"
echo -e " |               Thank you for use autopptp script!               |"
echo -e " |                                                                |"
echo -e " |                         Version: 1.0.0                         |"
echo -e " |                                                                |"
echo -e " |                     http://www.idcsrv.com                      |"
echo -e " |                                                                |"
echo -e " |                   Author:翅儿学飞(chier xuefei)                |"
echo -e " |                      Email:myregs@126.com                      |"
echo -e " |                         QQ:1810836851                          |"
echo -e " |                         QQ群:61749648                          |"
echo -e " |                                                                |"
echo -e " |          Hit [ENTER] to continue or ctrl+c to exit             |"
echo -e " |                                                                |"
printf " o----------------------------------------------------------------o\n"	
 read entcs 
clear
}

function _header() {
	printf " o----------------------------------------------------------------o\n"
	printf " | :: AutoPPTP                                v1.0.0 (2013/02/26) |\n"
	printf " o----------------------------------------------------------------o\n"	
}

##Program Function

################ Main ################
clear
_info_msg

if [ `id -u` != "0" ]; then
echo -e "You need to be be the root user to run this script.\nWe also suggest you use a direct root login, not su -, sudo etc..."
exit 1
fi

if [ ! -d $HomeDir ]; then
        mkdir -p $HomeDir
fi

cd $HomeDir || exit 1


## Install software

yum install -y $BasePkg

wget --no-check-certificate ${SrcHost}${SrcPath}dkms-2.0.17.5-1.noarch.rpm
wget --no-check-certificate ${SrcHost}${SrcPath}kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
wget --no-check-certificate ${SrcHost}${SrcPath}pptpd-1.3.4-2.el6.x86_64.rpm
rpm -ivh dkms-2.0.17.5-1.noarch.rpm
rpm -ivh kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
rpm -ivh pptpd-1.3.4-2.el6.x86_64.rpm

## Config PPTP
mv /etc/pptpd.conf /etc/pptpd.conf.bak
mv /etc/ppp/options.pptpd /etc/ppp/options.pptpd.bak
echo "ppp /usr/sbin/pppd" > /etc/pptpd.conf
echo "option /etc/ppp/options.pptpd" >> /etc/pptpd.conf
echo "logwtmp" >> /etc/pptpd.conf
echo "connections 50" >> /etc/pptpd.conf
echo "localip ${NatNet}.1" >> /etc/pptpd.conf
echo "remoteip ${NatNet}.2-254" >> /etc/pptpd.conf
echo "name pptpd" > /etc/ppp/options.pptpd
echo "refuse-pap" >> /etc/ppp/options.pptpd
echo "refuse-chap" >> /etc/ppp/options.pptpd
echo "refuse-mschap" >> /etc/ppp/options.pptpd
echo "require-mschap-v2" >> /etc/ppp/options.pptpd
echo "#require-mppe-128" >> /etc/ppp/options.pptpd
echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd
echo "proxyarp" >> /etc/ppp/options.pptpd
echo "lock" >> /etc/ppp/options.pptpd
echo "nobsdcomp" >> /etc/ppp/options.pptpd
echo "novj" >> /etc/ppp/options.pptpd
echo "novjccomp" >> /etc/ppp/options.pptpd
echo "nologfd" >> /etc/ppp/options.pptpd

/usr/bin/vpnuser add pptptest pptp123test

## Config System
depmod
modprobe ppp-compress-18 && echo "Load MPPE OK!" 
echo "modprobe ppp-compress-18" >> /etc/rc.local

sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g" /etc/sysctl.conf
echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
echo 1 > /proc/sys/net/ipv4/ip_forward

service iptables start
#/sbin/iptables -t nat -F
/sbin/iptables -t nat -I POSTROUTING -s ${NatNet}.0/255.255.255.0 -j SNAT --to-source $MyIP
/sbin/iptables -I INPUT -p gre -j ACCEPT
/sbin/iptables -I OUTPUT -p gre -j ACCEPT
/sbin/iptables -I FORWARD -p gre -j ACCEPT
service iptables save
service iptables restart
service pptpd restart
chkconfig --level 345 iptables on
chkconfig --level 345 pptpd on

###########  Clean Cache  ############
## Check System
echo ""
echo "############"
echo "If this is vps:"
echo "should show--> ppp:No such device or address && tun: File descriptor in bad state<--"
echo "############"
cat /dev/ppp
cat /dev/net/tun
echo "############"
echo "If 619 error then: rm /dev/ppp && mknod /dev/ppp c 108 0"
echo 'If 734 error then: sed -i "s/^require-mppe-128/^#require-mppe-128/g" /etc/ppp/options.pptpd'
rm -rf ${HomeDir}

