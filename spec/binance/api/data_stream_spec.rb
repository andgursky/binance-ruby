require "spec_helper"

RSpec.describe Binance::Api::UserDataStream do
  describe "#keepalive!" do
    subject { Binance::Api::UserDataStream.keepalive!(listen_key: "abc") }

    it { is_expected_block.to raise_error(Binance::Api::Error, /listenKey User Data Stream endpoints were removed/) }
  end

  describe "#start!" do
    subject { Binance::Api::UserDataStream.start! }

    it { is_expected_block.to raise_error(Binance::Api::Error, /listenKey User Data Stream endpoints were removed/) }
  end

  describe "#stop!" do
    subject { Binance::Api::UserDataStream.stop!(listen_key: "abc") }

    it { is_expected_block.to raise_error(Binance::Api::Error, /listenKey User Data Stream endpoints were removed/) }
  end

  describe "#margin_start!" do
    let(:listen_key) { "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1" }

    subject { Binance::Api::UserDataStream.margin_start! }

    context "and api succeeds" do
      let!(:request_stub) do
        stub_request(:post, "https://api.binance.com/sapi/v1/userDataStream")
          .to_return(status: 200, body: { listenKey: listen_key }.to_json)
      end

      it "responds with listen_key" do
        expect(subject).to eq(listen_key)
      end
    end
  end

  describe "#margin_keepalive!" do
    let(:listen_key) { "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1" }
    let(:params) { { listenKey: listen_key } }
    let(:request_body) { params.map { |key, value| "#{key}=#{value}" }.join("&") }

    subject { Binance::Api::UserDataStream.margin_keepalive!(listen_key: listen_key) }

    context "when listen_key is nil" do
      let(:listen_key) { nil }

      it { is_expected_block.to raise_error Binance::Api::Error }
    end

    context "when listen_key exists" do
      let!(:request_stub) do
        stub_request(:put, "https://api.binance.com/sapi/v1/userDataStream")
          .with(query: request_body)
          .to_return(status: 200, body: "{}")
      end

      it "should send api request" do
        subject
        expect(request_stub).to have_been_requested
      end
    end
  end
end
