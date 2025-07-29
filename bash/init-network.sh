#!/bin/bash
#system version
if [ -f /etc/debian_version ]; then
   system_version="debian"
elif [ -f /etc/redhat-release ]; then
   system_version="centos"
else
   echo "system version Unknown"
   exit;
fi

if [ $system_version == "debian" ]; then
    network_interface_file="/etc/network/interfaces"
    

eth1=/etc/network/interfaces
ipa=$(grep 'address' $eth1|sed -n '2p'|awk '{print $2}')
maska=$(grep 'netmask' $eth1|sed -n '2p'|awk '{print $2}')
gwa=$(grep 'gateway' $eth1|sed -n '2p'|awk '{print $2}')
dnsa=$(grep 'dns' $eth1|sed -n '2p'|awk '{print $2}')
ipb=$1
maskb=$2
gwb=$3
dnsb=$4
sed -i '/iface eth1/,/address/s/'$ipa'/'$ipb'/g' $eth1
sed -i '/iface eth1/,/netmask/s/'$maska'/'$maskb'/g' $eth1
sed -i '/iface eth1/,/gateway/s/'$gwa'/'$gwb'/g' $eth1
sed -i '/iface eth1/,/dns-nameservers/s/'$dnsa'/'$dnsb'/g' $eth1
ifconfig eth1 $ipb netmask $maskb
ip route add default via $gwb dev eth1
