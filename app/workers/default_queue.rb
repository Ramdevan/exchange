module Worker
  class DefaultQueue
    def process(payload, metadata, delivery_info)
      Rails.logger.info "Processing message: #{payload}"
    end

    def on_usr1
      Rails.logger.info "USR1 signal received"
    end

    def on_usr2
      Rails.logger.info "USR2 signal received"
    end
  end
end