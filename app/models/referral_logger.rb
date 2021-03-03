class ReferralLogger
	def self.debug(message=nil)
    @my_log ||= Logger.new("#{Rails.root}/log/referral.log")
    @my_log.debug(message) unless message.nil?
	end
end