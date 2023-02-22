require 'pry'
namespace :deposit do
  desc 'Some Deposits are not working properly, so we triggered manually using block ids'
  task manual_trigger: :environment do
      require File.join(Rails.root, 'app', 'services', 'coin_rpc.rb')
      require File.join(Rails.root, 'app', 'services', 'bnb.rb')
      require File.join(Rails.root, 'app', 'models', 'custom_logger.rb')

      DepositScheduleLogger.debug("Deposit rake is started #{DateTime.now}")
    begin
      missing_blocks = MissingBlock.get_blocks
      process_blocks(missing_blocks) unless missing_blocks.empty?
    rescue => e
      ExceptionNotifier.notify_exception(e)
      DepositScheduleLogger.debug("Deposit Error during processing: #{$!}")
    end
  end


  def process_blocks(block_details)
    block_details.find_each do |block_detail|
      currency = block_detail.currency
      block_id = block_detail.block_id
      DepositScheduleLogger.debug("block id #{block_id} is processing")
      ::CoinRPC[currency].exec_transaction(block_id)
    end
  end

end