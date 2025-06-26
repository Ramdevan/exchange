class AMQPConfig
  class << self
    def data
      @data ||= begin
        path = Rails.root.join('config', 'amqp.yml')
        YAML.load(ERB.new(File.read(path)).result)[Rails.env].symbolize_keys
      end
    end

    def connect
      data[:connect] || {}
    end

    def channel(id)
      data.dig(:channel, id) || {}
    end

    def binding_worker(id)
      "Worker::#{id.camelize}".constantize.new
    rescue NameError => e
      Rails.logger.warn "Worker class not found: #{e.message}, using DefaultQueue"
      Worker::DefaultQueue.new
    end

    def binding_queue(id)
      config = data.dig(:binding, id) || {}
      queue_name = config[:queue] || id
      [queue_name, { durable: true }]
    end

    def binding_exchange(id)
      data.dig(:binding, id, :exchange)
    end

    def routing_key(id)
      data.dig(:binding, id, :routing_key) || id
    end

    def topics(id)
      data.dig(:binding, id, :topics) || []
    end
  end
end