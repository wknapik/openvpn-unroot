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

Specific tests:

`make <system>+<test>`

where system is a directory directly under st/ (with a Dockerfile inside) and
test is a shell script placed either in st/common, or one of the system
directories (minus the ".sh" suffix).

e.g.:

`make arch+vpngate`

## Inspecting system tests

To investigate a problem found during STs, an executable other than a test
script can be called using the <system>+<executable> target format. E.g.:

`make fedora+bash`

will create the same container, as for any Fedora-based tests and run an
interactive bash session in it.

This mechanism is limited to executables in $PATH on the target system, due to
the special meaning of "/" in make.

## Passable make variables

VERBOSE=1 (print more output)  

## Notes

With UTs, there's some coverage, but nowhere near enough. With STs, the work is
only beginning.

The system test targets \*+vpngate cause a random [VPN
Gate](http://www.vpngate.net/) config to be downloaded. It's not guaranteed to
work. If it doesn't, delete vpngate.conf and run `make` again. Please try not
to abuse the services provided by VPN Gate volunteers.
