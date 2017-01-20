#!/usr/bin/env bats

load ../../openvpn-unroot
load ./test_helper/bats-support/load
load ./test_helper/bats-assert/load

setup() {
    tmp_file="$(mktemp)"
}

teardown() {
    rm -f "$tmp_file"
}

@test "get_new_user, static" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test01.conf" [user]=foo)
    run get_new_user
    assert_output foo
}

@test "get_new_user, generated" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test03.conf")
    run get_new_user
    assert_output nobody
}

@test "get_new_user, default" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test01.conf")
    run get_new_user
    assert_output openvpn
}

@test "get_new_group, static" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test01.conf" [group]=foo)
    run get_new_group bar
    assert_output foo
}

@test "get_new_group, generated, config group" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test03.conf")
    run get_new_group foo
    assert_output nobody
}

@test "get_new_group, generated, usergroup" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test01.conf")
    local -r random_user="$(getent passwd|shuf -n1|cut -d: -f1)"
    local -r random_user_group="$(getent group "$(getent passwd "$random_user"|cut -d: -f3)"|cut -d: -f1)"
    run get_new_group "$random_user"
    assert_output "$random_user_group"
}

@test "get_new_group, generated, user" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test01.conf")
    run get_new_group foo
    assert_output foo
}

@test "gen_group, nonexistent" {
    run gen_group nonexistent
    assert_output "groupadd nonexistent"
}

@test "gen_group, existent" {
    local -r random_group="$(getent group|shuf -n1|cut -d: -f1)"
    run gen_group "$random_group"
    assert_output ""
}

@test "gen_user, nonexistent" {
    run gen_user nonexistent_group nonexistent_user
    assert_output "useradd -g nonexistent_group -d / -s $(which nologin) nonexistent_user"
}

@test "gen_user, existent" {
    local -r random_user="$(getent passwd|shuf -n1|cut -d: -f1)"
    local -r random_user_group="$(getent group "$(getent passwd "$random_user"|cut -d: -f3)"|cut -d: -f1)"
    local -r random_group="$(getent group|grep -vxF "$random_user_group"|shuf -n1|cut -d: -f1)"
    run gen_user "$random_group" "$random_user"
    assert_output "usermod -aG $random_group $random_user"
}

@test "get_dev_type, no precedence" {
    local -A opt=([device]=tun31337 [old_config_file]="$BATS_TEST_DIRNAME/test01.conf")
    run get_dev_type
    assert_output tun
}

@test "get_dev_type, precedence" {
    local -A opt=([device]=openvpn-unroot-tun0 [old_config_file]="$tmp_file")
    echo -e "dev tun\ndev-type tap" >"$tmp_file"
    run get_dev_type
    assert_output tap
}

@test "get_new_device, static" {
    local -A opt=([device]=foo0)
    run get_new_device tun tun
    assert_output foo0
}

@test "get_new_device, generated, tun" {
    run get_new_device tun tun666
    assert_output tun666-unrooted
}

@test "get_new_device, generated, tap" {
    run get_new_device tap tap31337
    assert_output tap31337-unrooted
}

@test "get_old_down_file, no plugin, absolute, extension, no args" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test01.conf")
    run get_old_down_file
    assert_output /etc/openvpn/vpnfailsafe.sh
}

@test "get_old_down_file, no plugin, relative, extension, args" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test02.conf")
    run get_old_down_file
    assert_output ./foo.bar
}

@test "get_old_down_file, plugin, absolute, extension, no args" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test03.conf")
    run get_old_down_file
    assert_output /etc/openvpn/down.sh
}

@test "get_new_updown_file, static" {
    local -A opt=([up_file]=foobarbaz)
    run get_new_updown_file up /etc/openvpn/vpnfailsafe.sh
    assert_output foobarbaz
}

@test "get_new_updown_file, generated, absolute, extension" {
    run get_new_updown_file up /etc/openvpn/vpnfailsafe.sh
    assert_output /etc/openvpn/vpnfailsafe-unrooted.sh
}

@test "get_new_updown_file, generated, absolute, no extension" {
    run get_new_updown_file up /foo/bar
    assert_output /foo/bar-unrooted
}

@test "get_new_updown_file, generated, relative, extension" {
    run get_new_updown_file up foo.bar.bash
    assert_output foo.bar-unrooted.bash
}

@test "get_new_updown_file, generated, relative, no extension" {
    run get_new_updown_file up foo
    assert_output foo-unrooted
}

@test "get_new_iproute_file, static explicit" {
    local -A opt=([iproute_file]=/foo/bar.sh)
    run get_new_iproute_file foo bar baz
    assert_output /foo/bar.sh
}

@test "get_new_iproute_file, static implicit" {
    run get_new_iproute_file
    [[ ! -d /etc/openvpn/client ]] || local -r insert="/client"
    assert_output "/etc/openvpn$insert/ip-unrooted.sh"
}

@test "get_new_iproute_file, generated, updown" {
    run get_new_iproute_file '' /etc/openvpn/vpnfailsafe.sh /etc/openvpn/vpnfailsafe.sh /foo/example.conf
    assert_output /etc/openvpn/ip-unrooted.sh
}

@test "get_new_iproute_file, generated, conf" {
    run get_new_iproute_file '' '' '' /foo/example.conf
    assert_output /foo/ip-unrooted.sh
}

@test "get_new_iproute_file, generated, old_iproute_file-dot" {
    run get_new_iproute_file /etc/openvpn/iproute.sh '' '' /foo/example.conf
    assert_output /etc/openvpn/iproute-unrooted.sh
}

@test "get_new_iproute_file, generated, old_iproute_file-nodot" {
    run get_new_iproute_file /foo/bar '' '' /foo/example.conf
    assert_output /foo/bar-unrooted
}

@test "gen_iproute_file, no old_iproute_file" {
    run gen_iproute_file openvpn openvpn /dev/stdout
    assert_line -n 1 "exec sudo -u root $(which ip) \"\$@\""
}

@test "gen_iproute_file, old_iproute_file" {
    run gen_iproute_file openvpn openvpn /dev/stdout /foo/bar
    assert_line -n 1 "exec sudo -u root /foo/bar \"\$@\""
}

@test "gen_config_file, regular" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test01.conf")
    run gen_config_file /dev/stdout openvpn openvpn tun devfoo ipfoo upfoo downfoo
    exp_lines=("up upfoo" "down downfoo" "dev-type tun" "dev devfoo" "iproute ipfoo") # "persist-tun"
    for line in "${exp_lines[@]}"; do
        assert_line "$line"
    done
}

@test "gen_config_file, plugin" {
    local -A opt=([old_config_file]="$BATS_TEST_DIRNAME/test03.conf")
    run gen_config_file /dev/stdout openvpn openvpn tun devfoo ipfoo upfoo downfoo
    exp_lines=("up upfoo" "down downfoo" "dev-type tun" "dev devfoo" "iproute ipfoo") # "persist-tun"
    for line in "${exp_lines[@]}"; do
        assert_line "$line"
    done
}

@test "gen_sudoers_file, up_file, down_file, different, no old_iproute_file" {
    run gen_sudoers_file openvpn /dev/stdout /foo.sh ./bar 
    assert_output "openvpn ALL=(ALL) NOPASSWD: /usr/bin/ip, NOPASSWD:SETENV: /foo.sh, NOPASSWD:SETENV: ./bar"
}

@test "gen_sudoers_file, up_file, down_file, same, no old_iproute_file" {
    run gen_sudoers_file openvpn /dev/stdout /etc/openvpn/vpnfailsafe.sh /etc/openvpn/vpnfailsafe.sh
    assert_output "openvpn ALL=(ALL) NOPASSWD: /usr/bin/ip, NOPASSWD:SETENV: /etc/openvpn/vpnfailsafe.sh"
}

@test "gen_sudoers_file, up_file, down_file, same, old_iproute_file" {
    run gen_sudoers_file openvpn /dev/stdout /etc/openvpn/vpnfailsafe.sh /etc/openvpn/vpnfailsafe.sh /etc/openvpn/iproute
    assert_output "openvpn ALL=(ALL) NOPASSWD: /etc/openvpn/iproute, NOPASSWD:SETENV: /etc/openvpn/vpnfailsafe.sh"
}

@test "gen_sudoers_file, no up_file, no down_file, same, old_iproute_file" {
    run gen_sudoers_file openvpn /dev/stdout '' '' /etc/openvpn/iproute
    assert_output "openvpn ALL=(ALL) NOPASSWD: /etc/openvpn/iproute"
}

@test "gen_sudoers_file, no up_file, down_file, different, no old_iproute_file" {
    run gen_sudoers_file openvpn /dev/stdout '' '/etc/openvpn/down.sh'
    assert_output "openvpn ALL=(ALL) NOPASSWD: $(which ip), NOPASSWD:SETENV: /etc/openvpn/down.sh"
}

@test "gen_up_file" {
    run gen_up_file /etc/openvpn/vpnfailsafe.sh /dev/stdout openvpn openvpn
    assert_line -n 1 'exec sudo -u root -E /etc/openvpn/vpnfailsafe.sh "$@"'
}

@test "gen_netdev_file" {
    run gen_netdev_file tun tun0-unrooted openvpn openvpn /dev/stdout
    assert_output <<-EOF
		[NetDev]
		Kind=tun
		Name=tun0-unrooted
		
		[Tun]
		Group=openvpn
		User=openvpn
		EOF
}

@test "gen_unit_file" {
    [[ ! -f /usr/lib/systemd/system/openvpn-client@.service ]] || local -r suf=-client
    run diff -u "/usr/lib/systemd/system/openvpn${suf}@.service" <(gen_unit_file foo bar /dev/stdout)
    assert_line "+User=foo"
    assert_line "+Group=bar"
}

@test "gen_device" {
    run gen_device tun tun31337-unrooted openvpn openvpn
    assert_output "openvpn --mktun --dev-type tun --dev tun31337-unrooted --user openvpn --group openvpn"
}
