module Binance
  module Api
    class UserDataStream
      SPOT_LISTEN_KEY_REMOVED = <<~MSG.freeze
        Spot listenKey User Data Stream endpoints were removed by Binance on 2026-02-20.
        Use Binance::WebSocketApi#user_data_stream! instead
        (userDataStream.subscribe.signature on the WebSocket API).
        See https://developers.binance.com/docs/binance-spot-api-docs/websocket-api/user-data-stream-requests
      MSG

      class << self
        def keepalive!(listen_key: nil, api_key: nil, api_secret_key: nil)
          raise Error.new(message: SPOT_LISTEN_KEY_REMOVED)
        end

        def start!(api_key: nil, api_secret_key: nil)
          raise Error.new(message: SPOT_LISTEN_KEY_REMOVED)
        end

        def stop!(listen_key: nil, api_key: nil, api_secret_key: nil)
          raise Error.new(message: SPOT_LISTEN_KEY_REMOVED)
        end

        def margin_start!(api_key: nil, api_secret_key: nil)
          Request.send!(api_key_type: :none, method: :post, path: "/sapi/v1/userDataStream",
                        security_type: :user_stream, api_key: api_key, api_secret_key: api_secret_key)[:listenKey]
        end

        def margin_keepalive!(listen_key: nil, api_key: nil, api_secret_key: nil)
          raise Error.new(message: "listen_key is required") if listen_key.nil?
          Request.send!(api_key_type: :none, method: :put, path: "/sapi/v1/userDataStream",
                        params: { listenKey: listen_key }, security_type: :user_stream,
                        api_key: api_key, api_secret_key: api_secret_key)
        end
      end
    end
  end
end
