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

	ip rule show | grep " lookup $link" | sed "s/^[0-9]*:\s*\(.*\)\s*lookup $link/\1/g" | while read rule; do
		ip rule delete $rule table $link 
	done
	ip rule show | grep " lookup $link"

done


