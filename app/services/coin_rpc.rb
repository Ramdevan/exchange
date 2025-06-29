require 'net/http'
require 'uri'
require 'json'

class CoinRPC

  class JSONRPCError < RuntimeError; end
  class DepositError < RuntimeError; end
  class ConnectionRefusedError < StandardError; end

  def initialize(currency)
    @currency = currency
    @uri = URI.parse(currency.rpc)
    if currency.public_rpc
     @public_uri = URI.parse(currency.public_rpc)
    end
  end

  def self.[](currency)
    c = Currency.find_by_code(currency.to_s)
    if c && c.rpc
      name = c.code.upcase || 'BTC'
      "::CoinRPC::#{name}".constantize.new(c)
    end
  end

  def method_missing(name, *args)
    handle name, *args
  end

  def handle
    raise "Not implemented"
  end

  class BTC < self
    def handle(name, *args)
      post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end

    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      ExceptionNotifier.notify_exception(e)
      raise ConnectionRefusedError
    end

    def safe_getbalance
      begin
        getbalance
      rescue
        'N/A'
      end
    end

    def to_legacy_address address
      address
    end
  end


  class LTC < BTC
  end

  class BCHABC < BTC
    def getnewaddress label
      to_legacy_address( super(label) )
    end

    def to_legacy_address address
      CashAddr::Converter.to_legacy_address address
    end

    def to_cash_address address
      CashAddr::Converter.to_cash_address(address)
    end
  end

  class DASH < BTC
  end

  class ZEC < BTC
  end

end
