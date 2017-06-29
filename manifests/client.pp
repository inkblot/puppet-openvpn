# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::client (
    $connections,
    $device          = 'tap0',
    $port            = '5000',
    $address         = false,
    $hmac_algorithm  = 'SHA1',
    $cipher          = false,
    $tls_cipher      = false,
    $tls_auth_source = false,
    $server_dn       = false,
    $x509_name_type  = false,
    $ping            = false,
    $ping_restart    = false,
    $mtu_discovery   = true,
    $ca_cert_source  = undef,
    $ca_cert_content = undef,
    $cert_source     = undef,
    $cert_content    = undef,
    $key_source      = undef,
    $key_content     = undef,
) {
    include ::openvpn

    $_cipher = $cipher ? { true => $cipher, false => $::openvpn::cipher }
    $_tls_cipher = $tls_cipher ? { true => $tls_cipher, false => $::openvpn::tls_cipher }
    $_x509_name_type = $x509_name_type ? { true => $x509_name_type, false => $::openvpn::x509_name_type }

    $config_dir = $::openvpn::defaults::config_dir
    $vpn_dir = "${config_dir}/${name}"
    $ssl_dir = "${vpn_dir}/ssl"

    if (empty($ca_cert_source) and empty($ca_cert_content)) {
        fail('Must specify either ca_cert_source or ca_cert_content property of openvpn::client')
    }

    if (empty($cert_source) and empty($cert_content)) {
        fail('Must specify either cert_source or cert_content property of openvpn::client')
    }

    if (empty($key_source) and empty($key_content)) {
        fail('Must specify either key_source or key_content property of openvpn::client')
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

    file { "${ssl_dir}/client.crt":
        mode    => '0644',
        source  => $cert_source,
        content => $cert_content,
    }

    file { "${ssl_dir}/client.key":
        mode    => '0400',
        source  => $key_source,
        content => $key_content,
    }

    if $tls_auth_source {
        file { "${ssl_dir}/tls-auth.key":
            mode   => '0400',
            source => $tls_auth_source,
        }
    }

    concat { "${config_dir}/${name}.conf":
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['openvpn'],
    }

    concat::fragment { "openvpn-${name}-preamble":
        target  => "${config_dir}/${name}.conf",
        order   => '00',
        content => "# This file is managed by puppet\n",
    }

    concat::fragment { "openvpn-${name}-client":
        target  => "${config_dir}/${name}.conf",
        order   => '20',
        content => template('openvpn/client.conf.erb'),
    }
}
