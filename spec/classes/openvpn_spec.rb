require 'spec_helper'

describe 'openvpn' do
  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
  end
end

