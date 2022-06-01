module APIv2

  module ExceptionHandlers

    def self.included(base)
      base.instance_eval do
        rescue_from Grape::Exceptions::ValidationErrors do |e|
          ExceptionNotifier.notify_exception(e, env: 'production')
          Rack::Response.new({
            error: {
              code: 1001,
              message: e.message
            }
          }.to_json, e.status)
        end
      end
    end

  end

  class Error < Grape::Exceptions::Base
    attr :code, :text

    # code: api error code defined by Exchange, errors originated from
    # subclasses of Error have code start from 2000.
    # text: human readable error message
    # status: http status code
    def initialize(opts={})
      @code    = opts[:code]   || 2000
      @text    = opts[:text]   || ''

      @status  = opts[:status] || 400
      @exist   = opts[:exist] || 0
      @message = {error: {code: @code, message: @text, exist: @exist}}
    end
  end

  class AuthorizationError < Error
    def initialize
      super code: 2001, text: 'Authorization failed', status: 401
    end
  end

  class CreateOrderError < Error
    def initialize(e)
      super code: 2002, text: "Failed to create order. Reason: #{e}", status: 400
    end
  end

  class CancelOrderError < Error
    def initialize(e)
      super code: 2003, text: "Failed to cancel order. Reason: #{e}", status: 400
    end
  end

  class OrderNotFoundError < Error
    def initialize(id)
      super code: 2004, text: "Order##{id} doesn't exist.", status: 404
    end
  end

  class IncorrectSignatureError < Error
    def initialize(signature)
      super code: 2005, text: "Signature #{signature} is incorrect.", status: 401
    end
  end

  class TonceUsedError < Error
    def initialize(access_key, tonce)
      super code: 2006, text: "The tonce #{tonce} has already been used by access key #{access_key}.", status: 401
    end
  end

  class InvalidTonceError < Error
    def initialize(tonce, now)
      super code: 2007, text: "The tonce #{tonce} is invalid, current timestamp is #{now}.", status: 408
    end
  end

  class InvalidAccessKeyError < Error
    def initialize(access_key)
      super code: 2008, text: "Authorization failed.", status: 401
    end
  end

  class DisabledAccessKeyError < Error
    def initialize(access_key)
      super code: 2009, text: "Authorization has been disabled. Contact support.", status: 401
    end
  end

  class ExpiredAccessKeyError < Error
    def initialize(access_key)
      super code: 2010, text: "Authorization expired.", status: 401
    end
  end

  class OutOfScopeError < Error
    def initialize
      super code: 2011, text: "Requested API is out of access key scopes.", status: 401
    end
  end

  class DepositByTxidNotFoundError < Error
    def initialize(txid)
      super code: 2012, text: "Deposit##txid=#{txid} doesn't exist.", status: 404
    end
  end

  class RequiredFieldError < Error
    def initialize(field)
      super code: 2013, text: "#{field} is required.", status: 400
    end
  end

  class PathNotFoundError < Error
    def initialize
      super code: 2014, text: "Path not found.", status: 404
    end
  end

  class CustomError < Error
    def initialize(message, status = nil, record_exist=0)
      err_status = status ? status : 400
      super code: 2015, text: message, status: err_status, exist: record_exist
    end
  end

  class CreateMemberStakeCoinError < Error
    def initialize(e)
      super code: 2016, text: "Failed to invest in the stake plan. Reason: #{e}", status: 400
    end
  end

  class StakeCoinNotFoundError < Error
    def initialize(id)
      super code: 2017, text: "StakeCoin##{id} doesn't exist.", status: 404
    end
  end

  class MemberStakeCoinNotFoundError < Error
    def initialize(id)
      super code: 2019, text: "MemberStakeCoin##{id} doesn't exist.", status: 404
    end
  end

  class RedeemLockedInvestmentError < Error
    def initialize(e)
      super code: 2021, text: "Couldn't redeem the investment. Reason: #{e}.", status: 400
    end
  end
end
