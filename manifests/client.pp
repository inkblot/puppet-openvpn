# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::client (
    $device          = 'tap0',
    $port            = '5000',
    $address         = false,
    $hmac_algorithm  = 'SHA1',
    $cipher          = $::openvpn::defaults::cipher,
    $tls_cipher      = $::openvpn::defaults::tls_cipher,
    $tls_auth_source = false,
    $server_dn       = false,
    $connections,
    $ca_cert_source,
    $cert_source,
    $key_source,
) {
    $easy_rsa = $::openvpn::easy_rsa_path
    $vpn_dir = "/etc/openvpn/${name}"
    $ssl_dir = "${vpn_dir}/ssl"

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
        mode   => '0644',
        source => $ca_cert_source,
    }

    file { "${ssl_dir}/client.crt":
        mode   => '0644',
        source => $cert_source,
    }

    file { "${ssl_dir}/client.key":
        mode   => '0400',
        source => $key_source,
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
