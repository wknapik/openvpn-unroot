```
BETA WARNING: this is not mature code. Requires much more testing. Works on Arch Linux (for this one guy). May cause premature balding. More tests and support for other distros to come. Feedback appreciated.
```

# What is openvpn-unroot ?

`openvpn-unroot` is a script, that consumes an existing OpenVPN client config
and produces everything necessary to [run OpenVPN as an unprivileged
user](https://community.openvpn.net/openvpn/wiki/UnprivilegedUser). 

It is not a wrapper and only needs to be called once per config.

`openvpn-unroot` can infer everything it needs to know, but every aspect of its
operation can be explicitly controlled.

# Why use it ?

To minimize the impact of bugs and/or vulnerabilities on the system running
OpenVPN.

# How does it work ?

`openvpn-unroot` can produce any subset of the following:
* A user and/or group to run OpenVPN as.
* Sudoers entries necessary to call iproute and up/down scripts.
* Sudo wrappers for iproute and up/down scripts.
* A static tun/tap device and/or a systemd .netdev file to create the device on
  boot.
* A systemd unit to run OpenVPN on boot.
* An OpenVPN config, that puts all of the above together.

There are two modes of operation:
* With the --automagic switch - that makes `openvpn-unroot` "do the needful",
  without requiring any input from the user, other than an existing OpenVPN
  client config file. In this mode any specific settings can still be
  overridden manually.
* Without the --automagic switch - only the actions explicitly requested are
  performed and nothing is inferred.

# How do I install/use it ?

## TL;DR

Save the openvpn-unroot script somewhere, make it executable and run it as
root:
```
$ openvpn-unroot -av foo.conf
```
To enable and start the systemd service:
```
$ systemctl enable openvpn@foo-unrooted.service
$ systemctl start openvpn@foo-unrooted.service
```
That is the bare minimum and should usually suffice.

## Installation

`openvpn-unroot` is a standalone script. It can simply be downloaded, made
executable and used.

Arch Linux users may choose to install the
[openvpn-unroot-git](https://aur.archlinux.org/packages/openvpn-unroot-git/)
package from AUR instead.

## Usage

It's a good idea to start by running `openvpn-unroot` with the --automagic,
--pretend and --verbose options to see what *would* be done in the TL;DR
scenario above. For example:
```
$ openvpn -apv /etc/openvpn/client/foo.conf
INFO: Adding group openvpn
INFO: Adding user openvpn
INFO: Generating sudoers file /etc/sudoers.d/foo-unrooted
INFO: Generating iproute file /etc/openvpn/client/ip-unrooted.sh
INFO: Generating up file /etc/openvpn/client/vpnfailsafe-unrooted.sh
INFO: Adding device tun0-unrooted
INFO: Generating netdev file /etc/systemd/network/tun0-unrooted.netdev
INFO: Generating config file /etc/openvpn/client/foo-unrooted.conf
INFO: Generating unit file /etc/systemd/system/openvpn@foo-unrooted.service
$
```
If this is acceptable, the --pretend switch can be dropped, to perform all
these actions. If any of the choices made automatically are not to the user's
liking, they can be overridden using the switches described in the help message
printed by `openvpn-unroot -h`. 

Actions can be skipped entirely (using --no-\<option\>, or -S option1,option2),
or modified (using --\<option\> alternate_value).

For non-interactive use, the --automagic switch should be dropped and each
action should be explicitly specified instead. In that mode, if any options are
missing, an error will be returned, along with a message specifying what
switches to add.

# What are the requirements/assumptions/limitations ?

Requirements are minimal and should be met by any system running OpenVPN (list
available
[here](https://github.com/wknapik/openvpn-unroot/blob/master/package/arch/PKGBUILD)).

The only testing so far has been done on Arch Linux.

The script needs to be run as root.

Filenames supplied can't contain whitespace.

The persist-tun option is turned off in generated configs, due to a
[bug](https://community.openvpn.net/openvpn/ticket/812) in OpenVPN 2.4.0. This
will be changed when version 2.4.1, containing a fix, is released.

If a file that the chosen unprivileged user needs to be able to read is not
readable to them, a warning will be issued. For example, in Arch Linux, the
/etc/openvpn/client directory is not world-readable, so if any files end up
being placed there, it will trigger the warning. Arch Linux users can pass
`-g network` to `openvpn-unroot`, to avoid this issue.

# What are the security implications of using openvpn-unroot ?

As for `openvpn-unroot` itself - it should not be made setuid root, nor allowed
to be run with sudo by untrusted users, as that would allow them to run
arbitrary commands with root privileges.

The unprivileged user supplied to `openvpn-unroot` will be allowed to run the
`ip` command and the up/down scripts specified in the OpenVPN config (if any)
as root. The impact of the former is described by `man ip`, the latter depends
on the specific scripts. Anyone able to edit those scripts will also be able to
run arbitrary code as root.

As for running OpenVPN as an unprivileged user - as mentioned above, this
reduces the impact of bugs and expoitable vulnerabilities in OpenVPN, on the
system running it. Quoting the [OpenVPN
wiki](https://community.openvpn.net/openvpn/wiki/UnprivilegedUser):

> This is more secure than the built-in directives(--user and --group) because
> the openvpn process is never started with root permissions. Additionally,
> reconnects(including those which push fresh routes and configuration changes)
> which normally break after privileges are dropped via --user are handled
> without issue.

The "unrooting" can be combined with further [security
improvements](https://openvpn.net/index.php/open-source/documentation/howto.html#security).
