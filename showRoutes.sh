#!/bin/bash

grep -P "^\d+\s+[^\s]+" /etc/iproute2/rt_tables | sort -rn | while read id table; do
	[ "$id" = "0" ] && continue
	[ "$id" -gt "252" ] && continue
	echo "Table $id $table"
	ip route show table $table

done
