# ex: syntax=puppet ts=4 sw=4 si et

class openvpn (
    $openvpn_service = undef,
    $tls_cipher      = undef,
    $cipher          = undef,
    $x509_name_type  = undef,
) {
    include ::openvpn::defaults
    $openvpn_package = $::openvpn::defaults::openvpn_package

    package { 'openvpn':
        ensure => present,
        name   => $openvpn_package,
    }

    service { 'openvpn':
        ensure  => running,
        name    => $openvpn_service,
        require => Package['openvpn']
    }
}
