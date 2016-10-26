module Urabbit::RPC::Server
  def initialize(cloudamqp_url = ENV["CLOUDAMQP_URL"])
    @connection = Bunny.new(cloudamqp_url, logger: logger)
    @connection.start

    @channel = @connection.create_channel

    # TODO: Test which setting is the best
    # @channel.prefetch(1)
  end

  # TODO: Currently this is called directly, but it should
  # be called using server_engine.
  def start
    logger.info("Starting RPC server for #{self.class.name}")

    @queue = @channel.queue(self.class.queue_name)
    @exchange = @channel.default_exchange

    @queue.subscribe(block: true) do |delivery_info, properties, payload|
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
      end
    end

    logger.info("Stopped responding to RPC calls for #{self.class.name}")
  end

  # TODO: Use this method when server_engine is implemented.
  def stop
    @channel.close
    @connection.close

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
