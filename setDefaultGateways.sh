#!/bin/bash

links=$*
if [ -z "$links" ]; then
	links=$(ip link show|grep -o -P '(?<=^\d:\s)[^:]+')
fi

for link in $links; do
	[ "$link" = "lo" ] && continue

	echo "$link: Link found"

	tableId=$(grep -P "^\d+\s+$link" /etc/iproute2/rt_tables|awk '{ print $1 }')
	
	if [ -z "$tableId" ]; then
		echo "$link: Table is missing"
		tableId=$(grep -P '^\d' /etc/iproute2/rt_tables|grep -Pv '^0\s'|sort -n|head -1|awk '{ print $1 }')
		tableId=$(( tableId-1 ))
		echo "$tableId	$link" >> /etc/iproute2/rt_tables
	fi
	echo "$link: Table $tableId"

	inet=$(ip address show $link | grep -P '^\s*inet\s[^\s]+')
	ippr=$(echo $inet|awk '{ print $2 }')

	ip=${ippr%%/*}
	echo "$link: ip $ip"

	if [ "$ip" != "$ippr" ]; then
		prefix=${ippr##*/}
		network=$(ipcalc -n $ippr|cut -d= -f2)
	else
		peerpr=$(echo $inet|awk '{ print $4 }')
		network=${peerpr%%/*}
		prefix=${peerpr##*/}
	fi

	echo "$link: prefix $prefix"
	echo "$link: network $network"

	gateway=$(ip route|grep -oP "(?<=via )[\d.]+(?= dev $link)"|sort -fu)
	if [ -z "$gateway" ]; then
		gateway=$ip
	fi
	echo "$link: Gateway $gateway"

	ip route flush table $link
	ip rule show | grep " lookup $link" | sed "s/^[0-9]*:\s*\(.*\)\s*lookup $link/\1/g" | while read rule; do
		ip rule delete $rule table $link
	done


	ip route add $network/$prefix dev $link src $ip table $link
	ip route add default via $gateway table $link

	ip rule add from $ip table $link
	ip rule add to $ip table $link

	ip route flush cache

done


