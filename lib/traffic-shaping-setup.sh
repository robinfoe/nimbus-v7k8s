#! /usr/bin/env bash

set -o pipefail
set -o errexit
set -o nounset

# DELAY is the packet delay to inject. Since the nimbus gateway forward
# packets in both directions and this parameter is applied to all
# interfaces, it will end up being the *one way* delay. That is a delay
# of 300ms will result in a minimum RTT of 600ms (i.e. 300ms each way).
readonly DELAY=${DELAY:-"300ms"}

# THROUGHPUT is the (approximate) network throughput to configure. The
# rate is applied to the outbound queue, of which there is one in each
# direction, so even though packets traverse 2 interfaces each with their
# own rate limits, the total throughput still approximates what we set here.
readonly THROUGHPUT=${THROUGHPUT:-"1mbit"}

readonly PRIVATE_NET_PREFIX="192.168"

# Scrape the interfaces with routes to private nimbus networks. Expected output
# format is:
# 
# $ ip route show
# default via 10.186.207.254 dev eth0 proto dhcp metric 100
# 10.186.192.0/20 dev eth0 proto kernel scope link src 10.186.204.243 metric 100
# 192.168.111.0/24 dev eth1 proto kernel scope link src 192.168.111.1 metric 101
# 192.168.112.0/24 dev eth2 proto kernel scope link src 192.168.112.1 metric 102
# 192.168.113.0/24 dev eth3 proto kernel scope link src 192.168.113.1 metric 103
readonly NETDEV=$(ip route show | awk "/^${PRIVATE_NET_PREFIX}/ { print \$3 }")

for dev in ${NETDEV}; do
    tc qdisc del dev ${dev} root 2>/dev/null || true
    tc qdisc add dev ${dev} root netem delay ${DELAY} rate ${THROUGHPUT}
done

for dev in ${NETDEV}; do
    printf "%s: %s\n" ${dev} "$(tc qdisc show dev ${dev})"
done
