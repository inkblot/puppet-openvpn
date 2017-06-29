# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::server (
    $address,
    $bind_address          = $::ipaddress,
    $protocol              = 'udp',
    $port                  = '1194',
    $device                = 'tap0',
    $routes                = [],
    $client_isolation      = true,
    $crl_source            = false,
    $tls_auth_source       = false,
    $hmac_algorithm        = 'SHA1',
    $cipher                = false,
    $tls_cipher            = false,
    $ifconfig_pool         = false,
    $ifconfig_pool_persist = false,
    $ping                  = false,
    $ping_restart          = false,
    $mtu_discovery         = true,
    $up_script             = undef,
    $down_script           = undef,
    $user                  = undef,
    $group                 = undef,
    $ca_cert_source        = undef,
    $ca_cert_content       = undef,
    $cert_source           = undef,
    $cert_content          = undef,
    $key_source            = undef,
    $key_content           = undef,
) {
    include ::openvpn
    include ::openvpn::dh_params

    $_cipher = $cipher ? { true => $cipher, false => $::openvpn::cipher }
    $_tls_cipher = $tls_cipher ? { true => $tls_cipher, false => $::openvpn::tls_cipher }

    $config_dir = $::openvpn::defaults::config_dir

    $vpn_dir = "${config_dir}/${name}"
    $ssl_dir = "${vpn_dir}/ssl"
    $ccd_dir = "${name}/clients"
    $ifconfig_pool_persist_file = "${vpn_dir}/ifconfig_pool"
    $config_file = "${config_dir}/${name}.conf"

    if (empty($ca_cert_source) and empty($ca_cert_content)) {
        fail('Must specify either ca_cert_source or ca_cert_content property of openvpn::server')
    }

    if (empty($cert_source) and empty($cert_content)) {
        fail('Must specify either cert_source or cert_content property of openvpn::server')
    }

    if (empty($key_source) and empty($key_content)) {
        fail('Must specify either key_source or key_content property of openvpn::server')
    }

    File {
        ensure => present,
        owner  => 'root',
        group  => 'root',
        notify => Service['openvpn'],
    }

    file { $vpn_dir:
        ensure => directory,
        mode   => '0755',
    }

    file { $ssl_dir:
        ensure => directory,
        mode   => '0755',
    }

    concat { $config_file:
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        warn   => "# This file is managed by puppet\n",
        notify => Service['openvpn'],
    }

    concat::fragment { "openvpn-${name}-server":
        target  => $config_file,
        order   => '20',
        content => template('openvpn/server.conf.erb'),
    }

    file { "${ssl_dir}/ca.crt":
        mode    => '0644',
        source  => $ca_cert_source,
        content => $ca_cert_content,
    }

    file { "${ssl_dir}/server.crt":
        mode    => '0644',
        source  => $cert_source,
        content => $cert_content,
    }

    file { "${ssl_dir}/server.key":
        mode    => '0400',
        source  => $key_source,
        content => $key_content,
    }

    if $crl_source {
        file { "${ssl_dir}/crl.pem":
            mode   => '0444',
            source => $crl_source,
        }
    }

    concat::fragment { "openvpn-${name}-ssl":
        target  => $config_file,
        order   => '30',
        content => template('openvpn/server-ssl.conf.erb'),
    }

    if $tls_auth_source {
        file { "${ssl_dir}/tls-auth.key":
            mode   => '0400',
            source => $tls_auth_source,
        }
    }

    file { "${config_dir}/${ccd_dir}":
        ensure => directory,
        mode   => '0755',
    }
}
