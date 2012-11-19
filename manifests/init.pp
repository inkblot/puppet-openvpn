# ex:ts=4 sw=4 tw=72

class openvpn {
	include openvpn::params
	include openvpn::install
	include openvpn::service
}
