# RPC::Client is a low level RPC client for RabbitMQ.
# It does not assume anything about message format.
#
# Usage:
#
# begin
#   client = RPC::Client.new
#   result = client.call(routing_key, message)
# rescue RPC::Client::Error => exception
#    puts exception.message
#    puts excpetion.cause
# end
#
# routing_key - a function name
# message     - a String with function params as JSON
# result      - a String with the result as JSON or nil in case of error
# exception   - an Exception with message describing what went wrong,
#               can be thrown during initialization and method calls.
#               It can also contain a cause raised from Bunny itself.
class Urabbit::RPC::Client
  class Error < Exception; end
  class ServerError < Error; end

  def initialize(cloudamqp_url = ENV["CLOUDAMQP_URL"])
    @connection = Bunny.new(cloudamqp_url, logger: Urabbit.logger)
    @connection.start

    @channel = @connection.create_channel
    @exchange = @channel.default_exchange
    @reply_queue = @channel.queue("amq.rabbitmq.reply-to")

    @lock = Mutex.new
    @condition = ConditionVariable.new

    @reply_queue.subscribe do |delivery_info, properties, payload|
      if properties[:correlation_id] == @correlation_id
        # Headers are only present if explicitly set.
        if error = properties.to_hash.dig(:headers, 'error')
          @error = error
        else
          @result = payload
        end

        @lock.synchronize{@condition.signal}
      end
    end
  rescue Bunny::Exception
    raise Error.new("Error connecting to queue")
  end

  def call(routing_key, message, timeout = 10)
    @correlation_id = SecureRandom.uuid

    @exchange.publish(message,
      routing_key: routing_key,
      correlation_id: @correlation_id,
      reply_to: "amq.rabbitmq.reply-to"
    )

    @lock.synchronize{@condition.wait(@lock, timeout)}

    if @error.nil? && @result.nil?
      raise Error.new("Timed out waiting for reply. "\
        "Make sure the RPC queue name is correct.")
    end

    if @error
      raise ServerError.new(@error['message'])
    else
      @result
    end
  rescue Bunny::Exception
    raise Error.new("Error communicating with queue")
  end
end
