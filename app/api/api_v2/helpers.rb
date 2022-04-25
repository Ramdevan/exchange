module APIv2
  module Helpers
    extend Grape::API::Helpers

    def authenticate!
      current_user or raise AuthorizationError
    end

    def redis
      @r ||= KlineDB.redis
    end

    def current_user
      @current_user ||= current_token.try(:member)
    end

    def current_token
      @current_token ||= env['api_v2.token']
    end

    def current_market
      @current_market ||= Market.find params[:market]
    end

    def time_to
      params[:timestamp].present? ? Time.at(params[:timestamp]) : nil
    end

    def build_order(attrs)
      klass = attrs[:side] == 'sell' ? OrderAsk : OrderBid

      order = klass.new(
        source:        'APIv2',
        state:         ::Order::WAIT,
        member_id:     current_user.id,
        ask:           current_market.base_unit,
        bid:           current_market.quote_unit,
        currency:      current_market.id,
        ord_type:      attrs[:ord_type] || 'limit',
        price:         attrs[:price],
        volume:        attrs[:volume],
        origin_volume: attrs[:volume]
      )
    end

    def create_order(attrs)
      order = build_order attrs
      Ordering.new(order).submit
      order
    rescue => e
      ExceptionNotifier.notify_exception(e)
      Rails.logger.info "Failed to create order: #{$!}"
      Rails.logger.debug order.inspect
      Rails.logger.debug $!.backtrace.join("\n")
      raise CreateOrderError, $!
    end

    def create_orders(multi_attrs)
      orders = multi_attrs.map {|attrs| build_order attrs }
      Ordering.new(orders).submit
      orders
    rescue => e
      ExceptionNotifier.notify_exception(e)
      Rails.logger.info "Failed to create order: #{$!}"
      Rails.logger.debug $!.backtrace.join("\n")
      raise CreateOrderError, $!
    end

    def login_member(email, password)
      member = Member.find_by(email: email)

      unless member.present? && member.identity.authenticate(password)
        raise CustomError, @params[:message] = 'Invalid Email or Password'
      end
      
      @current_user ||= Member.current = member

      # creating new access key & secret key
      current_user.mobile_api_token.delete if current_user.mobile_api_token.present?
      token = current_user.create_mobile_api_token
      token.scopes = 'all'
      token.save

      # Send mail for activated user - if login succeed
      MemberMailer.notify_signin(member.id).deliver if member.activated?

      token
    end

    def create_or_update_documents(document, attachments, document_file, bill_file)
      if attachments.present? && attachments != []
        attachments.each do |attachment|
          if attachment.type == "Asset::IdDocumentFile"
            document.id_document_file_attributes = {
                :id => attachment.id,
                :file => document_file
            }
          elsif attachment.type == "Asset::IdBillFile"
            document.id_bill_file_attributes = {
                :id => attachment.id,
                :file => bill_file
            }
          end
        end
      else
        document.id_document_file_attributes = {
            :file => document_file
        }
        document.id_bill_file_attributes = {
            :file => bill_file
        }
      end

      document
    end

    def two_factor_auth_verified?
      return false if not current_user.two_factors.activated?
      return false if two_factor_failed_locked?

      two_factor = current_user.two_factors.by_type(params[:two_factor_type])
      return false if not two_factor

      two_factor.assign_attributes(otp: params[:two_factor_otp])
      if two_factor.verify?
        clear_two_factor_auth_failed
        true
      else
        increase_two_factor_auth_failed
        false
      end
    end

    def one_time_password_verified?
      @google_auth.assign_attributes(otp: params[:gauth_otp])
      @google_auth.verify?
    end

    def two_factor_failed_locked?
      failed_two_factor_auth > 10
    end

    def failed_two_factor_auth_key
      "xubiq:session:#{request.ip}:failed_two_factor_auths"
    end

    def failed_two_factor_auth
      Rails.cache.read(failed_two_factor_auth_key) || 0
    end

    def increase_two_factor_auth_failed
      Rails.cache.write(failed_two_factor_auth_key, failed_two_factor_auth+1, expires_in: 1.month)
    end

    def clear_two_factor_auth_failed
      Rails.cache.delete failed_two_factor_auth_key
    end

    def order_param
      params[:order_by].downcase == 'asc' ? 'id asc' : 'id desc'
    end

    def format_ticker(ticker)
      { at: ticker[:at],
        ticker: {
          buy: ticker[:buy],
          sell: ticker[:sell],
          low: ticker[:low],
          high: ticker[:high],
          last: ticker[:last],
          vol: ticker[:volume]
        }
      }
    end

    def clear_all_sessions(member_id)
      if redis = Rails.cache.instance_variable_get(:@data)
        redis.keys("xubiq:sessions:#{member_id}:*").each {|k| Rails.cache.delete k.split(':').last }
      end

      Rails.cache.delete_matched "xubiq:sessions:#{member_id}:*"
    end

    def get_k_json
      key = "xubiq:#{params[:market]}:k:#{params[:period]}"

      if params[:timestamp] && params[:endtimestamp]
        get_range_data(key)
      elsif params[:timestamp]
        ts = JSON.parse(redis.lindex(key, 0)).first
        offset = (params[:timestamp] - ts) / 60 / params[:period]
        offset = 0 if offset < 0

        JSON.parse('[%s]' % redis.lrange(key, offset, offset + params[:limit] - 1).join(','))
      else
        length = redis.llen(key)
        offset = [length - params[:limit], 0].max
        JSON.parse('[%s]' % redis.lrange(key, offset, -1).join(','))
      end
    end

    def get_range_data(key)
      ts = JSON.parse(redis.lindex(key, 0)).first rescue 0

      # Finding the offset
      starttime = (params[:timestamp] - ts) / 60 / params[:period]
      endtime = (params[:endtimestamp] - ts) / 60 / params[:period]
      data_count = redis.llen(key)
      if starttime < 0 && (endtime < 0 || data_count < endtime)
        data = []
      elsif starttime < 0 || endtime < 0
        starttime = 0
        JSON.parse('[%s]' % redis.lrange(key, starttime, starttime + params[:limit] - 1).join(','))
      else
        JSON.parse('[%s]' % redis.lrange(key, starttime, endtime).join(','))
      end
    end
  end
end
