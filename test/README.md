# Testing openvpn-unroot

## Running all tests

`make`

## Static analysis ([shellcheck](https://github.com/koalaman/shellcheck))

`make sa`

## Unit tests ([bats](https://github.com/sstephenson/bats), including [bats-support](https://github.com/ztombol/bats-support) and [bats-assert](https://github.com/ztombol/bats-assert))

`make ut`

## System tests (make + docker)

All of them:

`make st`

Or specific tests:

`make <system>+<test>`

where system is a directory directly under st/ (with a Dockerfile inside) and
test is a shell script placed either in st/common, or one of the system
directories.

e.g.:

`make arch+vpngate`

## Passable make variables

VERBOSE=1 (print more output)  
SA_ALL=1 (do not pass -e SC2155 to shellcheck)

## Notes

With UTs, there's some coverage, but nowhere near enough. With STs, the work is
only beginning.

The system test targets \*+vpngate cause a random [VPN
Gate](http://www.vpngate.net/) config to be downloaded. It's not guaranteed to
work. If it doesn't, delete vpngate.conf and run `make` again. Please try not
to abuse the services provided by VPN Gate volunteers.
