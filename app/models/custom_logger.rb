class CustomLogger
	def self.debug(message=nil)
    @my_log ||= Logger.new("#{Rails.root}/log/custom.log")
    @my_log.debug(message) unless message.nil?
	end
end

class DepositTrackLogger
  def self.debug(message=nil)
	@deposit_track_log ||= Logger.new("#{Rails.root}/log/deposit_track.log")
	@deposit_track_log.debug(message) unless message.nil?
  end
end

# deposit is triggered using block ids in background job
class DepositScheduleLogger
  def self.debug(message=nil)
  @deposit_schedule_log ||= Logger.new("#{Rails.root}/log/deposit_schedule.log")
  @deposit_schedule_log.debug(message) unless message.nil?
  end
end