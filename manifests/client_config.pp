# ex: syntax=puppet ts=4 sw=4 si et

define openvpn::client_config (
    $vpn,
    $client_name  = false,
    $address      = false,
    $routes       = [],
    $iroutes      = [],
    $ping         = false,
    $ping_restart = false,
) {
    if $client_name {
        $real_name = $client_name
    } else {
        $real_name = $name
    }

    file { "/etc/openvpn/${vpn}/clients/${real_name}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('openvpn/client_config.erb'),
        notify  => Service['openvpn'],
    }
}
