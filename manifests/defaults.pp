# ex: syntax=puppet ts=4 sw=4 si et

class openvpn::defaults (
    $config_dir,
    $openvpn_package,
    $scoped_service_prefix,
    $scoped_service_suffix,
) {}
