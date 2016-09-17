# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::server (
    $address,
    $ca_cert_source,
    $cert_source,
    $key_source,
    $dh_params_source,
    $bind_address     = $::ipaddress,
    $protocol         = 'udp',
    $port             = '1194',
    $device           = 'tap0',
    $routes           = [],
    $client_isolation = true,
    $crl_source       = false,
    $tls_auth_source  = false,
    $hmac_algorithm   = 'SHA1',
    $cipher           = $::openvpn::defaults::cipher,
    $tls_cipher       = $::openvpn::defaults::tls_cipher,
    $ifconfig_pool    = false,
    $ping             = false,
    $ping_restart     = false,
    $mtu_discovery    = true,
) {
    $vpn_dir = "/etc/openvpn/${name}"
    $ssl_dir = "${vpn_dir}/ssl"
    $ccd_dir = "${name}/clients"

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

    file { "${ssl_dir}/server.crt":
        mode   => '0644',
        source => $cert_source,
    }

    file { "${ssl_dir}/server.key":
        mode   => '0400',
        source => $key_source,
    }

    file { "${ssl_dir}/dh_params.pem":
        mode   => '0400',
        source => $dh_params_source,
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
        ensure  => directory,
        mode    => '0755',
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
