module Withdraws
  module Coinable
    extend ActiveSupport::Concern

    def set_fee
      self.fee = WithdrawChannel.find_by(currency: currency_obj.code).fee.to_d
    end

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def audit!
      result = CoinRPC[currency].validateaddress(fund_uid)

      if result.nil? || (result[:isvalid] == false)
        Rails.logger.info "#{self.class.name}##{id} uses invalid address: #{fund_uid.inspect}"
        reject
        save!
      elsif (result[:ismine] == true) || PaymentAddress.find_by_address(fund_uid) || PaymentAddress.where("address LIKE ?", "#{fund_uid}%").present?
        Rails.logger.info "#{self.class.name}##{id} uses hot wallet address: #{fund_uid.inspect}"
        self.txid = Withdraw::INTERNAL_TRANSFER
	save!

	super # Transfer to withdraw#audit!
      else
        super
      end
    end

    def as_json(options={})
      super(options).merge({
                             display_type: self.display_type,
                             blockchain_url: blockchain_url
                           })
    end

  end
end

