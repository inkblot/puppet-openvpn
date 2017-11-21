# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::server (
    $address,
    $bind_address          = $::ipaddress,
    $protocol              = 'udp',
    $port                  = '1194',
    $device                = 'tap0',
    $routes                = [],
    $client_isolation      = true,
    $crl_source            = undef,
    $crl_content           = undef,
    $duplicate_cn          = true,
    $float                 = true,
    $tls_auth_source       = undef,
    $tls_auth_content      = undef,
    $hmac_algorithm        = 'SHA1',
    $cipher                = false,
    $tls_cipher            = false,
    $ifconfig_pool         = false,
    $ifconfig_pool_persist = false,
    $remote_cert_tls       = false,
    $ping                  = false,
    $ping_restart          = false,
    $persist_key           = true,
    $persist_tun           = true,
    $persist_local_ip      = true,
    $persist_remote_ip     = true,
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
    $vault_pki_path        = 'openvpn',
    $vault_pki_role        = 'openvpn-server',
    $vault_pki_common_name = $::facts['networking']['fqdn'],
    $vault_min_wait        = undef,
    $vault_max_wait        = undef,
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
    $service_ensure = $::openvpn::service_ensure
    $service_enable = $::openvpn::service_enable

    if ($cert_source == "vault") {
        if (empty($vault_pki_path)) {
            fail('Must specify vault_pki_path with cert_source => vault')
        }

        if (empty($vault_pki_role)) {
            fail('Must specify vault_pki_role with cert_source => vault')
        }

        if (empty($vault_pki_common_name)) {
            fail('Must specify vault_pki_common_name with cert_source => vault')
        }

        $_config_file = "${config_dir}/${name}.ctmpl"
    } else {
        if (empty($ca_cert_source) and empty($ca_cert_content)) {
            fail('Must specify either ca_cert_source or ca_cert_content property of openvpn::server')
        }

        if (empty($cert_source) and empty($cert_content)) {
            fail('Must specify either cert_source or cert_content property of openvpn::server')
        }

        if (empty($key_source) and empty($key_content)) {
            fail('Must specify either key_source or key_content property of openvpn::server')
        }

        $_config_file = $config_file
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

    concat { $_config_file:
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        warn    => "# This file is managed by puppet\n",
        require => Package['openvpn'],
        notify  => Service['openvpn'],
    }

    if !empty($tls_auth_content) {
        $_tls_auth_source = "${ssl_dir}/tls-auth.key"
        file { $_tls_auth_source:
            mode    => '0400',
            content => $tls_auth_content,
        }
    } elsif !empty($tls_auth_source) {
        $_tls_auth_source = $tls_auth_source
    } else {
        $_tls_auth_source = false
    }

    concat::fragment { "openvpn-${name}-server":
        target  => $_config_file,
        order   => '20',
        content => template('openvpn/server.conf.erb'),
    }

    if ($cert_source == 'vault') {
        hashicorp::consul_template::template { $config_file:
            source   => $_config_file,
            mode     => '0600',
            command  => inline_template($::openvpn::defaults::template_command),
            min_wait => $vault_min_wait,
            max_wait => $vault_max_wait,
        }

        concat::fragment { "openvpn-${name}-ssl":
            target  => $_config_file,
            order   => '30',
            content => template('openvpn/vault-certificates.conf.erb'),
        }
    } else {
        if !empty($ca_cert_content) {
            $_ca_cert_source = "${ssl_dir}/ca.crt"
            file { $_ca_cert_source:
                mode    => '0644',
                content => $ca_cert_content,
            }
        } else {
            $_ca_cert_source = $ca_cert_source
        }

        if !empty($cert_content) {
            $_cert_source = "${ssl_dir}/server.crt"
            file { $_cert_source:
                mode    => '0644',
                content => $cert_content,
            }
        } else {
            $_cert_source = $cert_source
        }

        if !empty($key_content) {
            $_key_source = "${ssl_dir}/server.key"
            file { $_key_source:
                mode    => '0400',
                content => $key_content,
            }
        } else {
            $_key_source = $key_source
        }

        if !empty($crl_content) {
            $_crl_source = "${ssl_dir}/crl.pem"
            file { $_crl_content:
                mode    => '0444',
                content => $crl_content,
            }
        } elsif !empty($crl_source) {
            $_crl_source = $crl_source
        } else {
            $_crl_source = false
        }

        concat::fragment { "openvpn-${name}-ssl":
            target  => $_config_file,
            order   => '30',
            content => template('openvpn/server-ssl.conf.erb'),
        }
    }

    file { "${config_dir}/${ccd_dir}":
        ensure => directory,
        mode   => '0755',
    }

    $scoped_service_prefix = $::openvpn::defaults::scoped_service_prefix
    $scoped_service_suffix = $::openvpn::defaults::scoped_service_suffix

    if ($scoped_service_prefix or $scoped_service_suffix) {
        $service_stem = $scoped_service_prefix ? {
            false   => $name,
            default => "${scoped_service_prefix}${name}"
        }
        $scoped_service = $scoped_service_suffix ? {
            false   => $service_stem,
            default => "${service_stem}${scoped_service_suffix}"
        }

        Concat[$_config_file] ~>
        service { $scoped_service:
            ensure    => $service_ensure,
            enable    => $service_enable,
        }
    }
}
