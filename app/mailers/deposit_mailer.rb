class DepositMailer < BaseMailer

  def accepted(deposit_id)
    @deposit = Deposit.find deposit_id
    @member = @deposit.member
    mail to: @deposit.member.email
  end

  def submitted(deposit_id)
    @deposit_id = deposit_id
    retry_on_error(5) { @deposit = Deposit.find @deposit_id }
    @member = @deposit.member
    mail to: @deposit.member.email
  end

  # THIS METHODS WILL RUN 1+retry_count TIMES AND FAIL
  def retry_on_error(retry_count, &block)
    block.call
  rescue => e
    Rails.logger.debug "Failed to find deposit record: #{$!}"
    if retry_count > 0
      sleep 0.2
      retry_count -= 1
      Rails.logger.debug "Retrying to find deposit record for deposit_id #{@deposit_id}.."
      retry
    else
      Rails.logger.debug "Failed to find deposit record for deposit_id #{@deposit_id}.."
      raise $!
    end
  end

end
