# encoding: UTF-8
# frozen_string_literal: true

require_relative 'constants'

module Matching
  class StopLossOrder < StopOrder
    attr :id, :timestamp, :type, :price, :locked, :market, :source
    attr_accessor(:volume, :started)

    def initialize(attrs)
      @id           = attrs[:id]
      @timestamp    = attrs[:timestamp]
      @trigger_cond = attrs[:trigger_cond].to_sym
      @type         = attrs[:type].to_sym
      @volume       = attrs[:volume].to_d
      @price        = attrs[:price].to_d
      @source       = attrs[:source]
      @locked       = attrs[:locked].to_d
      @market       = Market.find attrs[:market]
      @started      = attrs[:started] ? true : false

      raise InvalidOrderError.new(attrs) unless valid?
    end

    def trade_with(counter_order, counter_book)
      if counter_order.is_a?(LimitOrder)
        if @started or crossed?(counter_order.price)
          @started = true
          trade_price  = counter_order.price
          trade_volume = [volume, volume_limit(trade_price), counter_order.volume].min
          trade_funds  = trade_price*trade_volume
          [trade_price, trade_volume, trade_funds]
        end
      else
        trade_volume = [volume, volume_limit(trade_price), counter_order.volume, counter_order.volume_limit(price)].min
        trade_funds  = price*trade_volume
        [price, trade_volume, trade_funds]
      end
    end

    def volume_limit(trade_price)
      type == :ask ? locked : locked/trade_price
    end

    def fill(trade_price, trade_volume, trade_funds)
      raise NotEnoughVolume if trade_volume > @volume
      @volume -= trade_volume

      funds = type == :ask ? trade_volume : trade_funds
      raise ExceedSumLimit if funds > @locked
      @locked -= funds
    end

    def filled?
      volume <= ZERO or locked <= ZERO
    end

    def crossed?(price)
      if type == :ask
        price >= @price # if people offer price higher or equal than ask limit
      else
        price <= @price # if people offer price lower or equal than bid limit
      end
    end

    def label
      "%d/$%s/%s" % [id, price.to_s('F'), volume.to_s('F')]
    end

    def valid?
      return false unless [:ask, :bid].include?(type)
      id && timestamp && market && price > ZERO
    end

    def attributes
      { id: @id,
        timestamp: @timestamp,
        type: @type,
        locked: @locked,
        volume: @volume,
        market: @market.id,
        source: @source,
        ord_type: 'market' }
    end

  end
end
