# ex:ts=4 sw=4 tw=72

class openvpn::install {
	package { 'openvpn':
		ensure => present,
	}
}
