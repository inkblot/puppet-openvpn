# ex: syntax=puppet ts=4 sw=4 si et

class openvpn (
    $openvpn_package,
    $openvpn_service,
) {
    include ::openvpn::defaults

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
