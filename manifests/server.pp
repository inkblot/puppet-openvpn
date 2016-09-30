# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::server (
    $bind_address          = $::ipaddress,
    $protocol              = 'udp',
    $port                  = '1194',
    $device                = 'tap0',
    $routes                = [],
    $client_isolation      = true,
    $crl_source            = false,
    $tls_auth_source       = false,
    $hmac_algorithm        = 'SHA1',
    $cipher                = $::openvpn::defaults::cipher,
    $tls_cipher            = $::openvpn::defaults::tls_cipher,
    $ifconfig_pool         = false,
    $ifconfig_pool_persist = false,
    $ping                  = false,
    $ping_restart          = false,
    $mtu_discovery         = true,
    $up_script             = undef,
    $down_script           = undef,
    $user                  = undef,
    $group                 = undef,
    $ca_cert_source        = '',
    $ca_cert_content       = '',
    $cert_source           = '',
    $cert_content          = '',
    $key_source            = '',
    $key_content           = '',
    $dh_params_source      = '',
    $dh_params_content     = '',
    $address,
) {
    $vpn_dir = "/etc/openvpn/${name}"
    $ssl_dir = "${vpn_dir}/ssl"
    $ccd_dir = "${name}/clients"
    $ifconfig_pool_persist_file = "${vpn_dir}/ifconfig_pool"

    if (empty($ca_cert_source) and empty($ca_cert_content)) {
        fail('Must specify either ca_cert_source or ca_cert_content property of openvpn::server')
    }

    if (empty($cert_source) and empty($cert_content)) {
        fail('Must specify either cert_source or cert_content property of openvpn::server')
    }

    if (empty($key_source) and empty($key_content)) {
        fail('Must specify either key_source or key_content property of openvpn::server')
    }

    if (empty($dh_params_source) and empty($dh_params_content)) {
        fail('Must specify either dh_params_source or dh_params_content property of openvpn::server')
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

    file { "${ssl_dir}/dh_params.pem":
        mode    => '0400',
        source  => $dh_params_source,
        content => $dh_params_content,
    }

    if $tls_auth_source {
        file { "${ssl_dir}/tls-auth.key":
            mode   => '0400',
            source => $tls_auth_source,
        }
    }

    if $crl_source {
        file { "${ssl_dir}/crl.pem":
            mode   => '0444',
            source => $crl_source,
        }
    }

    file { "/etc/openvpn/${ccd_dir}":
        ensure => directory,
        mode   => '0755',
    }

    concat { "/etc/openvpn/${name}.conf":
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['openvpn'],
    }

    concat::fragment { "openvpn-${name}-preamble":
        target  => "/etc/openvpn/${name}.conf",
        order   => '00',
        content => "# This file is managed by puppet\n",
    }

    concat::fragment { "openvpn-${name}-server":
        target  => "/etc/openvpn/${name}.conf",
        order   => '20',
        content => template('openvpn/server.conf.erb'),
    }
}
