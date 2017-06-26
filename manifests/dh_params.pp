# ex: syntax=puppet ts=4 sw=4 si et

class openvpn::dh_params (
    $size,
) {
    include ::openvpn

    $config_dir = $::openvpn::defaults::config_dir

    Package['openvpn'] ->
    exec { 'openvpn dhparams generator':
        command => "/usr/bin/openssl dhparam -out ${config_dir}/dh_params.pem ${size}",
        creates => "${config_dir}/dh_params.pem",
        timeout => 0,
    } ~>
    Service['openvpn']
}
