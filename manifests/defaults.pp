# ex: syntax=puppet ts=4 sw=4 si et

class openvpn::defaults (
    $tls_cipher,
    $cipher,
    $use_verify_x509_name,
) {}
