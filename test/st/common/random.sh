#!/usr/bin/env bash
set -eEo pipefail
openvpn-unroot -av -g network ./random.conf
echo -e "remap-usr1 SIGTERM\nconnect-retry-max 1" >>./random-unrooted.conf
while read -r -t 10 line; do
    echo "$line"
    case "$line" in
        *" Initialization Sequence Completed")
           echo "SUCCESS!"
           exit 0;;
    esac
done < <(sudo -u openvpn -g network openvpn ./random-unrooted.conf)
exit 1
