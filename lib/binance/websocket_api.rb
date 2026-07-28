require "securerandom"

module Binance
  # Spot WebSocket API client (wss://ws-api.binance.com).
  # Use this for User Data Stream subscriptions after the listenKey REST endpoints were removed.
  class WebSocketApi < Faye::WebSocket::Client
    class Error < StandardError; end

    USER_DATA_EVENTS = %i[
      outboundAccountPosition
      balanceUpdate
      executionReport
      listStatus
      listenKeyExpired
      eventStreamTerminated
      externalLockUpdate
    ].freeze

    def initialize(on_open: nil, on_close: nil, api_key: nil, api_secret_key: nil)
      wss_uri = if ENV["BINANCE_TEST_NET_ENABLE"]
          "wss://ws-api.testnet.binance.vision/ws-api/v3"
        else
          "wss://ws-api.binance.com:443/ws-api/v3"
        end

      super wss_uri, nil, ping: 180

      @api_key = api_key
      @api_secret_key = api_secret_key
      @user_data_handler = nil
      @subscribe_on_open = false
      @subscribe_options = {}
      @subscription_id = nil

      on :open do |event|
        send_user_data_subscribe! if @subscribe_on_open
        on_open&.call(event)
      end

      on :message do |event|
        process_data(event.data)
      end

      on :close do |event|
        on_close&.call(event)
      end
    end

    # Subscribe to Spot user data events via userDataStream.subscribe.signature.
    # Works with HMAC, RSA, and Ed25519 API keys (HMAC signing used by this gem).
    #
    # Yields |subscription_id, event_data| for each user data event.
    def user_data_stream!(api_key: nil, api_secret_key: nil, recv_window: nil, &on_receive)
      raise ArgumentError, "block required" unless on_receive

      @user_data_handler = on_receive
      @subscribe_options = {
        api_key: api_key,
        api_secret_key: api_secret_key,
        recv_window: recv_window,
      }

      if ready_state == Faye::WebSocket::API::OPEN
        send_user_data_subscribe!
      else
        @subscribe_on_open = true
      end
    end

    def user_data_unsubscribe!(subscription_id: nil)
      params = {}
      params[:subscriptionId] = subscription_id unless subscription_id.nil?
      request("userDataStream.unsubscribe", params)
    end

    private

    def send_user_data_subscribe!
      @subscribe_on_open = false
      options = @subscribe_options || {}
      api_key = options[:api_key] || @api_key || Api::Configuration.api_key
      api_secret_key = options[:api_secret_key] || @api_secret_key

      raise Error.new("API key is required for user data stream") if api_key.nil? || api_key.empty?

      params = {
        apiKey: api_key,
        timestamp: Api::Configuration.timestamp.to_i,
      }
      params[:recvWindow] = options[:recv_window] unless options[:recv_window].nil?

      signed = Api::Configuration.signed_ws_api_params(params: params, api_secret_key: api_secret_key)
      request("userDataStream.subscribe.signature", signed)
    end

    def request(method, params = {})
      payload = {
        id: SecureRandom.uuid,
        method: method,
      }
      payload[:params] = params unless params.nil? || params.empty?
      send(payload.to_json)
    end

    def process_data(data)
      json = JSON.parse(data, symbolize_names: true)

      if json.key?(:event)
        dispatch_user_event(json[:subscriptionId], json[:event])
      elsif json.key?(:status)
        process_response(json)
      end
    end

    def process_response(json)
      if json[:status] != 200
        error = json[:error] || {}
        raise Error.new("(#{error[:code]}) #{error[:msg]}")
      end

      subscription_id = json.dig(:result, :subscriptionId)
      @subscription_id = subscription_id unless subscription_id.nil?
    end

    def dispatch_user_event(subscription_id, event)
      return unless event.is_a?(Hash)

      event_type = event[:e]&.to_sym
      return unless event_type.nil? || USER_DATA_EVENTS.include?(event_type)

      @user_data_handler&.call(subscription_id, event)
    end
  end
end
