module Urabbit::RPC::Server
  SleepInterval = 1 # How often to check if server should stop.

  # TODO: Currently this is called directly, but it should
  # be called using server_engine.
  def start
    @channel = Urabbit.create_channel
    logger.info("Starting RPC server for #{self.class.name}")

    @queue = @channel.queue(self.class.queue_name)
    @exchange = @channel.default_exchange

    @queue.subscribe do |delivery_info, properties, payload|
      begin
        result = work(payload)

        @exchange.publish(result,
          routing_key: properties.reply_to,
          correlation_id: properties.correlation_id
        )
      rescue => exception
        @exchange.publish("",
          routing_key: properties.reply_to,
          correlation_id: properties.correlation_id,
          headers: {
            error: {
              code: 500,
              message: exception.message
            }
          }
        )

        logger.warn(
          "RPC Server for #{self.class.name} responded with an error "\
          "due to an exception: #{exception.inspect} caused by payload: "\
          "#{payload.inspect}"
        )
      end
    end

    # Subscribing in blocking mode above disables auto-reconnection feature.
    # It's better to just sleep.
    until(@should_stop) do
      sleep(SleepInterval)
    end

    logger.info("Stopped responding to RPC calls for #{self.class.name}")
  end

  # TODO: Use this method when server_engine is implemented.
  def stop
    @should_stop = true
    logger.info("Stopped RPC server for #{self.class.name}")
  end

  private

  def logger
    Urabbit.logger
  end

  def self.included(base)
   base.extend ClassMethods
  end

  module ClassMethods
    attr_reader :queue_name

    def from_queue(queue_name)
      @queue_name = queue_name
    end
  end
end
