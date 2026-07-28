require "spec_helper"

RSpec.describe Binance::Api::Configuration do
  after(:each) { 
    Binance::Api::Configuration.api_key = nil 
    Binance::Api::Configuration.read_info_api_key = nil
    Binance::Api::Configuration.trading_api_key = nil 
    Binance::Api::Configuration.withdrawals_api_key = nil 
    Binance::Api::Configuration.secret_key = nil
  }

  describe '.api_key' do
    before(:each) { Binance::Api::Configuration.api_key = '123' }
    subject { Binance::Api::Configuration.api_key }
    it { is_expected.to eq('123') }
  end
  [:none, :read_info, :trading, :withdrawals].freeze
  
  describe '.read_info_api_key' do
    before(:each) { Binance::Api::Configuration.read_info_api_key = 'read_info' }
    subject { Binance::Api::Configuration.api_key(type: :read_info) }
    it { is_expected.to eq('read_info') }
  end

  describe '.trading_api_key' do
    before(:each) { Binance::Api::Configuration.trading_api_key = 'trading' }
    subject { Binance::Api::Configuration.api_key(type: :trading) }
    it { is_expected.to eq('trading') }
  end
  
  describe '.withdrawals_api_key' do
    before(:each) { Binance::Api::Configuration.withdrawals_api_key = 'withdrawals' }
    subject { Binance::Api::Configuration.api_key(type: :withdrawals) }
    it { is_expected.to eq('withdrawals') }
  end
  
  describe '.secret_key' do
    before(:each) { Binance::Api::Configuration.secret_key = '456' }
    subject { Binance::Api::Configuration.secret_key }
    it { is_expected.to eq('456') }
  end

  describe '.signed_ws_api_params' do
    before { Binance::Api::Configuration.secret_key = 'NhqPtmdSJYdKjVHjA7PZj4Mge3R5YNiP1e3UZjInClVN65XAbvqqM6A7H5fATj0j' }

    it 'returns params with an HMAC signature over alphabetically sorted keys' do
      params = {
        timestamp: 1645423376532,
        apiKey: 'vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A',
      }

      signed = Binance::Api::Configuration.signed_ws_api_params(params: params)
      payload = "apiKey=#{params[:apiKey]}&timestamp=#{params[:timestamp]}"
      expect(signed[:signature]).to eq(
        Binance::Api::Configuration.signed_request_signature(payload: payload)
      )
    end
  end
end