require 'spec_helper'

describe 'openvpn::server' do
  let(:pre_condition) { "class {'openvpn': cipher => 'AES-192-CBC'}" }
  context 'when fed no cipher' do
    let (:title) { 'my_server'}
    let (:params) do
      {
        'address' => '8.8.8.8/32',
        'ca_cert_content' => 'ca_cert_content',
        'cert_content' => 'cert_content',
        'key_content' => 'key_content',
      }
    end
    it { should contain_concat('/etc/openvpn/my_server.conf') }
    it 'should use cipher from openvpn' do
      should contain_concat__fragment('openvpn-my_server-server')
        .with_target('/etc/openvpn/my_server.conf')
        .with_content(%r{^cipher AES-192-CBC$})
    end
  end

  context 'when ciper set to AES-256-CBC' do
    let (:title) { 'my_server'}
    let (:params) do
      {
        'address' => '8.8.8.8/32',
        'ca_cert_content' => 'ca_cert_content',
        'cert_content' => 'cert_content',
        'key_content' => 'key_content',
	'cipher' => 'AES-256-CBC',
      }
    end
    it { should contain_concat('/etc/openvpn/my_server.conf') }
    it 'should use cipher from openvpn' do
      should contain_concat__fragment('openvpn-my_server-server')
        .with_target('/etc/openvpn/my_server.conf')
        .with_content(%r{^cipher AES-256-CBC$})
    end
  end

end

