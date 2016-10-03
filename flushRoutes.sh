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
		continue
	fi
	echo "$link: Table $tableId"

	ip route show table $link
	ip route flush table $link
	ip route show table $link

done


