# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::client (
    $device               = 'tap0',
    $port                 = '5000',
    $address              = false,
    $hmac_algorithm       = 'SHA1',
    $cipher               = $::openvpn::defaults::cipher,
    $tls_cipher           = $::openvpn::defaults::tls_cipher,
    $tls_auth_source      = false,
    $use_verify_x509_name = $::openvpn::defaults::use_verify_x509_name,
    $server_dn            = false,
    $x509_name_type       = $::openvpn::defaults::x509_name_type,
    $ping                 = false,
    $ping_restart         = false,
    $mtu_discovery        = true,
    $connections,
    $ca_cert_source,
    $ca_cert_content,
    $cert_source,
    $cert_content,
    $key_source,
    $key_content,
) {
    $easy_rsa = $::openvpn::easy_rsa_path
    $vpn_dir = "/etc/openvpn/${name}"
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
        mode   => 0755,
    }

    file { $ssl_dir:
        ensure => directory,
        mode   => 0755,
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

    concat { "/etc/openvpn/${name}.conf":
        owner  => 'root',
        group  => 'root',
        mode   => 0644,
        notify => Service['openvpn'],
    }

    concat::fragment { "openvpn-${name}-preamble":
        target  => "/etc/openvpn/${name}.conf",
        order   => '00',
        content => "# This file is managed by puppet\n",
    }

    concat::fragment { "openvpn-${name}-client":
        target  => "/etc/openvpn/${name}.conf",
        order   => '20',
        content => template('openvpn/client.conf.erb'),
    }
}
