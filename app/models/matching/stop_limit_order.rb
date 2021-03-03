require_relative 'constants'

module Matching
  class StopLimitOrder < StopOrder
    attr :id, :timestamp, :type, :price, :stop_price, :market, :source, :trigger_cond
    attr_accessor :volume

    def initialize(attrs)
      @id = attrs[:id]
      @timestamp = attrs[:timestamp]
      @trigger_cond = attrs[:trigger_cond].to_sym
      @type = attrs[:type].to_sym
      @volume = attrs[:volume].to_d
      @price = attrs[:price].to_d
      @stop_price = attrs[:stop_price].to_d
      @source = attrs[:source]
      @market = Market.find attrs[:market]

      raise InvalidOrderError.new(attrs) unless valid?(attrs)
    end

    def trade_with(counter_order, counter_book)
      if counter_order.is_a?(LimitOrder)
        if crossed?(counter_order.price)
          # Cancel Stop limit and create limit order
          @trigger_cond = "="
        else
          # update condition for target price
          if @price > counter_order.price
            @trigger_cond = ">="
          else
            @trigger_cond = "<="
          end
        end
      else
        trade_volume = [volume, counter_order.volume, counter_order.volume_limit(price)].min
        trade_funds = price * trade_volume
        [price, trade_volume, trade_funds]
      end
    end

    def fill(trade_price, trade_volume, trade_funds)
      raise NotEnoughVolume if trade_volume > @volume
      @volume -= trade_volume
    end

    def filled?
      volume <= ZERO
    end

    def crossed?(price)
      price == @price # if people stop price is equal with the top limit order price
    end

    def label
      "%d/$%s/%s" % [id, price.to_s('F'), volume.to_s('F')]
    end

    def valid?(attrs)
      return false unless [:ask, :bid].include?(type)
      id && timestamp && market && price > ZERO
    end

    def attributes
      { id: @id,
        timestamp: @timestamp,
        type: @type,
        volume: @volume,
        price: @price,
        market: @market.id,
        source: @source,
        ord_type: 'limit' }
    end

  end
end
