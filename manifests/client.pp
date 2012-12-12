# ex:ts=4 sw=4 tw=72

define openvpn::client (
	$key_size            = 1024,
	$ca_expiration_days  = 3650,
	$key_expiration_days = 3650,
	$default_md          = 'sha256',
	$clientcn            = $::fqdn,
	$country             = "US",
	$province            = "AB",
	$city                = "Springfield",
	$org                 = "Snake Oil",
	$email               = "snakeoil@example.com",
) {
	$easy_rsa = $::openvpn::params::easy_rsa
	$vpn_dir = "/etc/openvpn/${name}"
	$ssl_dir = "${vpn_dir}/ssl"
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
		"openvpn-${name}-init-ssl":
			command => ". ${vars} && clean-all",
			creates => "${ssl_dir}/index.txt",
			before  => Exec["openvpn-${name}-client-csr"];

		"openvpn-${name}-client-csr":
			command => ". ${vars} && pkitool --csr ${clientcn}",
			creates => "${ssl_dir}/${clientcn}.csr",
			before  => File["${ssl_dir}/${clientcn}.csr"];
	}
}
