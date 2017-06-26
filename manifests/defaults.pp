# ex: syntax=puppet ts=4 sw=4 si et

class openvpn::defaults (
    $config_dir,
    $tls_cipher,
    $cipher,
    $use_verify_x509_name,
    $x509_name_type,
) {}
