# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::client_config (
    $vpn,
    $address      = false,
    $routes       = [],
    $iroutes      = [],
    $ping         = false,
    $ping_restart = false,
) {
    file { "/etc/openvpn/${vpn}/clients/${name}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('openvpn/client_config.erb'),
        notify  => Service['openvpn'],
    }
}