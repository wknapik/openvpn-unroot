#!/usr/bin/env bash
set -eEo pipefail
[[ "$1" != verbose ]] || readonly maybe_v="v"
openvpn-unroot -a"$maybe_v" ./random.conf
echo -e "remap-usr1 SIGTERM\nconnect-retry-max 1" >>./random-unrooted.conf
while read -r -t 10 line; do
    echo "$line"
    case "$line" in
        *" Initialization Sequence Completed")
           echo "SUCCESS!"
           exit 0;;
    esac
done < <(sudo -u openvpn openvpn ./random-unrooted.conf)
exit 1
