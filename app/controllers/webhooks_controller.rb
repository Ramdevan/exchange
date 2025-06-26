class WebhooksController < ApplicationController
  before_action :auth_anybody!
  skip_before_action :verify_authenticity_token

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

  def xrp
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "ripple")
      render :json => {:status => "queued"}
    end
  end  

  def bnb
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "bnb")
      render :json => {:status => "queued"}
    end
  end

  def busd
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "busd")
      render :json => {:status => "queued"}
    end
  end

  def tmd
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "tmd")
      render :json => {:status => "queued"}
    end
  end

  def tmc
    if params[:type] == "transaction" && params[:hash].present?
      AMQPQueue.enqueue(:deposit_coin, txid: params[:hash], channel_key: "tmc")
      render :json => {:status => "queued"}
    end
  end

end
