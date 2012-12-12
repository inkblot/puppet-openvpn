# ex:ts=4 sw=4 tw=72

define openvpn::server (
	$key_size            = 1024,
	$ca_expiration_days  = 3650,
	$key_expiration_days = 3650,
	$default_md          = 'sha256',
	$server_cn           = 'server',
	$country             = "US",
	$province            = "AB",
	$city                = "Springfield",
	$org                 = "Snake Oil",
	$email               = "snakeoil@example.com",
	$local_address,
	$bind_address        = $::ipaddress,
	$intranet,
	$intranet_netmask,
	$intranet_gateway,
	$routes              = [],
) {
	$easy_rsa = $::openvpn::params::easy_rsa
	$vpn_dir = "/etc/openvpn/${name}"
	$ssl_dir = "${vpn_dir}/ssl"
	$ccd_dir = "${vpn_dir}/clients"
	$vars = "${vpn_dir}/easy-rsa.vars"
	$opensslcnf = "${vpn_dir}/openssl.cnf"
	
	file {
		$vpn_dir:
			ensure => directory,
			owner  => 'root',
			group  => 'root',
			mode   => 0755,
			notify => Service['openvpn'];

		$ssl_dir:
			ensure => directory,
			owner  => 'root',
			group  => 'root',
			mode   => 0755;

		$ccd_dir:
			ensure  => directory,
			owner   => 'root',
			group   => 'root',
			mode    => 0755,
			purge   => true,
			recurse => true;

		$vars:
			ensure  => present,
			owner   => 'root',
			group   => 'root',
			mode    => 0644,
			content => template('openvpn/easy-rsa.vars.erb');

		$opensslcnf:
			ensure  => present,
			owner   => 'root',
			group   => 'root',
			mode    => 0644,
			content => template('openvpn/openssl.cnf.erb');
	}

	Exec {
		path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin', $easy_rsa ],
		user     => 'root',
		provider => 'shell',
	}

	exec {
		"openvpn-${name}-init-dh-params":
			command => ". ${vars} && clean-all && build-dh",
			creates => "${ssl_dir}/dh1024.pem",
			require => [ File[$vars], File[$opensslcnf] ],
			before  => Exec["openvpn-${name}-init-ca"];

		"openvpn-${name}-init-ca":
			command => ". ${vars} && pkitool --initca",
			creates => "${ssl_dir}/ca.key",
			require => [ File[$vars], File[$opensslcnf] ],
			before  => Exec["openvpn-${name}-server-cert"];

		"openvpn-${name}-server-cert":
			command => ". ${vars} && pkitool --server ${server_cn}",
			creates => "${ssl_dir}/${server_cn}.key",
			before  => Concat["/etc/openvpn/${name}.conf"];
	}

	concat { "/etc/openvpn/${name}.conf":
		owner  => 'root',
		group  => 'root',
		mode   => 0644,
	}

	concat::fragment { "openvpn-${name}-preamble":
		target  => "/etc/openvpn/${name}.conf",
		order   => '00',
		content => "# This file is managed by puppet\n",
	}

	concat::fragment { "openvpn-${name}-server":
		target  => "/etc/openvpn/${name}.conf",
		order   => '20',
		content => template('openvpn/server.conf.erb'),
	}
}
