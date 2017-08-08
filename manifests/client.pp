# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::client (
    $connections,
    $device                = 'tap0',
    $port                  = '5000',
    $address               = false,
    $hmac_algorithm        = 'SHA1',
    $cipher                = false,
    $tls_cipher            = false,
    $tls_auth_source       = undef,
    $tls_auth_content      = undef,
    $server_dn             = false,
    $x509_name_type        = false,
    $ping                  = false,
    $ping_restart          = false,
    $mtu_discovery         = true,
    $ca_cert_source        = undef,
    $ca_cert_content       = undef,
    $cert_source           = undef,
    $cert_content          = undef,
    $key_source            = undef,
    $key_content           = undef,
    $vault_pki_path        = 'openvpn',
    $vault_pki_role        = 'openvpn-server',
    $vault_pki_common_name = $::facts['networking']['fqdn'],
) {
    include ::openvpn

    $_cipher = $cipher ? { true => $cipher, false => $::openvpn::cipher }
    $_tls_cipher = $tls_cipher ? { true => $tls_cipher, false => $::openvpn::tls_cipher }
    $_x509_name_type = $x509_name_type ? { true => $x509_name_type, false => $::openvpn::x509_name_type }

    $config_dir = $::openvpn::defaults::config_dir
    $vpn_dir = "${config_dir}/${name}"
    $ssl_dir = "${vpn_dir}/ssl"
    $config_file = "${config_dir}/${name}.conf"

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
            fail('Must specify either ca_cert_source or ca_cert_content property of openvpn::client')
        }

        if (empty($cert_source) and empty($cert_content)) {
            fail('Must specify either cert_source or cert_content property of openvpn::client')
        }

        if (empty($key_source) and empty($key_content)) {
            fail('Must specify either key_source or key_content property of openvpn::client')
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

    concat::fragment { "openvpn-${name}-client":
        target  => $_config_file,
        order   => '20',
        content => template('openvpn/client.conf.erb'),
    }

    if ($cert_source == 'vault') {
        hashicorp::consul_template::template { $config_file:
            source  => $_config_file,
            mode    => '0600',
            command => inline_template($::openvpn::defaults::template_command),
        }

        concat::fragment { "openvpn-${name}-ssl":
            target  => $_config_file,
            order   => '30',
            content => template('openvpn/vault-certificates.conf.erb'),
        }
    } else {
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

        concat::fragment { "openvpn-${name}-ssl":
            target  => $_config_file,
            order   => '30',
            content => template('openvpn/client-ssl.conf.erb'),
        }
    }

    if !(empty($tls_auth_source) and empty($tls_auth_content)) {
        file { "${ssl_dir}/tls-auth.key":
            mode    => '0400',
            source  => $tls_auth_source,
            content => $tls_auth_content,
        }
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

        service { $scoped_service:
            ensure => $service_ensure,
            enable => $service_enable,
        }
    }
}
