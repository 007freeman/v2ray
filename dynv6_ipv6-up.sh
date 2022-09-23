#!/bin/sh -e
# based on https://gist.github.com/corny/7a07f5ac901844bd20c9
# modify by trotter; May 13, 2021 

#hostname=$1
#device=$2

# Enter the relevant parameters in line 10-12. “device” enter the interface name, such as pppoe0, switch0, it is recommended to enter pppoe0.

token=your token
hostname=example.dynv6.net
device=pppoe0

file=$HOME/.dynv6.addr6
[ -e $file ] && old=`cat $file`

if [ -z "$hostname" -o -z "$token" ]; then
  echo "Usage: token=<your-authentication-token> [netmask=64] $0 your-name.dynv6.net [device]"
  exit 1
fi

if [ -z "$netmask" ]; then
  netmask=128
fi

if [ -n "$device" ]; then
  device="dev $device"
fi

#address=$(ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)

if [ -e /usr/bin/curl ]; then
  bin="curl -fsS"
elif [ -e /usr/bin/wget ]; then
  bin="wget -O-"
else
  echo "neither curl nor wget found"
  exit 1
fi

#if [ -z "$address" ]; then
#  echo "no IPv6 address found"
#  exit 1
#fi

# When the address is empty, wait for 1 minute and then assign the value again. The loop ends after 30 times.
i=1
while [ $i -lt 30 ]
do
  address=$(ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)
  if [ -z "$address" ]; then
    sleep 1m
    ((i++))
    else
      break
  fi
done

# address with netmask
current=$address/$netmask

if [ "$old" = "$current" ]; then
  echo "IPv6 address unchanged"
  exit
fi

# send addresses to dynv6
$bin "http://dynv6.com/api/update?hostname=$hostname&ipv6=$current&token=$token"
$bin "http://ipv4.dynv6.com/api/update?hostname=$hostname&ipv4=auto&token=$token"

# save current address
echo $current > $file