require "spec_helper"

RSpec.describe Binance::WebSocketApi do
  let(:api_key) { "vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A" }
  let(:secret_key) { "NhqPtmdSJYdKjVHjA7PZj4Mge3R5YNiP1e3UZjInClVN65XAbvqqM6A7H5fATj0j" }
  let(:handlers) { {} }
  let(:sent_payloads) { [] }
  let(:websocket) { Binance::WebSocketApi.new }

  before do
    stub_request(:any, "wss://ws-api.binance.com:443/ws-api/v3").to_return(status: 200, body: "")
    Binance::Api::Configuration.api_key = api_key
    Binance::Api::Configuration.secret_key = secret_key

    allow_any_instance_of(Binance::WebSocketApi).to receive(:on) do |_ws, kind, &block|
      handlers[kind] = block
    end
    allow_any_instance_of(Binance::WebSocketApi).to receive(:ready_state).and_return(Faye::WebSocket::API::OPEN)
    allow_any_instance_of(Binance::WebSocketApi).to receive(:send) do |_ws, payload|
      sent_payloads << JSON.parse(payload, symbolize_names: true)
    end
  end

  after do
    Binance::Api::Configuration.api_key = nil
    Binance::Api::Configuration.secret_key = nil
  end

  describe "#user_data_stream!" do
    it "sends userDataStream.subscribe.signature with a valid HMAC signature" do
      websocket.user_data_stream! { |_id, _data| }

      expect(sent_payloads.length).to eq(1)
      request = sent_payloads.first
      expect(request[:method]).to eq("userDataStream.subscribe.signature")
      expect(request[:params][:apiKey]).to eq(api_key)
      expect(request[:params][:timestamp]).to eq(Binance::Api::Configuration.timestamp.to_i)
      expect(request[:params][:signature]).to be_a(String)
      expect(request[:params][:signature].length).to eq(64)
    end

    it "signs params in alphabetical order" do
      websocket.user_data_stream! { |_id, _data| }

      params = sent_payloads.first[:params]
      expected_payload = "apiKey=#{api_key}&timestamp=#{params[:timestamp]}"
      expected_signature = Binance::Api::Configuration.signed_request_signature(payload: expected_payload)
      expect(params[:signature]).to eq(expected_signature)
    end

    context "when the subscribe response is an error" do
      it "raises WebSocketApi::Error" do
        websocket.user_data_stream! { |_id, _data| }

        expect {
          handlers[:message].call(
            OpenStruct.new(
              data: {
                id: "abc",
                status: 400,
                error: { code: -2015, msg: "Invalid API-key" },
              }.to_json
            )
          )
        }.to raise_error(Binance::WebSocketApi::Error, "(-2015) Invalid API-key")
      end
    end

    context "when a user data event arrives" do
      let(:execution_report) do
        JSON.parse(File.read("spec/fixtures/executionReport.json"), symbolize_names: true)
      end

      it "invokes the handler with subscription id and event" do
        received = nil
        websocket.user_data_stream! { |subscription_id, data| received = [subscription_id, data] }

        handlers[:message].call(
          OpenStruct.new(
            data: {
              subscriptionId: 0,
              event: execution_report,
            }.to_json
          )
        )

        expect(received).to eq([0, execution_report])
      end
    end

    context "when an outboundAccountPosition event arrives" do
      it "invokes the handler" do
        received = nil
        websocket.user_data_stream! { |_id, data| received = data }

        handlers[:message].call(
          OpenStruct.new(
            data: {
              subscriptionId: 0,
              event: {
                e: "outboundAccountPosition",
                E: 1,
                u: 1,
                B: [],
              },
            }.to_json
          )
        )

        expect(received[:e]).to eq("outboundAccountPosition")
      end
    end
  end

  describe "#user_data_unsubscribe!" do
    it "sends userDataStream.unsubscribe" do
      websocket.user_data_unsubscribe!(subscription_id: 0)

      expect(sent_payloads.first[:method]).to eq("userDataStream.unsubscribe")
      expect(sent_payloads.first[:params][:subscriptionId]).to eq(0)
    end
  end
end
