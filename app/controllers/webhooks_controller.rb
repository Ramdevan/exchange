class WebhooksController < ApplicationController
  before_action :auth_anybody!
  skip_before_filter :verify_authenticity_token

  def btc
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "satoshi")
      render :json => {:status => "queued"}
    end
  end

  def eth
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "ether")
      render :json => {:status => "queued"}
    end
  end

  def usdt
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "usdt")
      render :json => {:status => "queued"}
    end
  end
  def enj
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "enj")
      render :json => {:status => "queued"}
    end
  end
  def mana
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "mana")
      render :json => {:status => "queued"}
    end
  end

  def usdc
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "usdc")
      render :json => {:status => "queued"}
    end
  end

  def bchabc
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "bcash")
      render :json => {:status => "queued"}
    end
  end

  def ltc
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "litecoin")
      render :json => {:status => "queued"}
    end
  end

  def dash
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "dash")
      render :json => {:status => "queued"}
    end
  end

  def zec
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "zcash")
      render :json => {:status => "queued"}
    end
  end

  def xmr
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "monero")
      render :json => {:status => "queued"}
    end
  end

  def xrp
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "ripple")
      render :json => {:status => "queued"}
    end
  end

  def neo
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "neo")
      render :json => {:status => "queued"}
    end
  end

  def citiusd
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "citiusd")
      render :json => {:status => "queued"}
    end
  end

end
