#!/bin/bash

iptables -t nat -F
iptables -t mangle -F
iptables -F
