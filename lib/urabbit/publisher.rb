# Usage:
# begin
#   pubisher = Publisher.new(
#     exchange_name: "courier_tracker",
#     routing_key: "in.courier_statuses.created"
#   )
#   publisher.publish(message)
# rescue Publisher::Error => exception
#   puts exception.message
#   puts exception.cause
# end
#
# Message is usually a JSON.
# Exception can contain a cause raised from Bunny.
class Urabbit::Publisher
  class Error < Exception; end

  def initialize(opts)
    cloudamqp_url = opts[:cloudamqp_url] || ENV["CLOUDAMQP_URL"]
    exchange_type = opts[:exchange_type] || :topic
    exchange_name = opts[:exchange_name] ||
      raise(Error, "Please provide an 'exchange_name'")
    @routing_key = opts[:routing_key] ||
      raise(Error, "Please provide a 'routing_key'")

    @connection = Bunny.new(cloudamqp_url, logger: Urabbit.logger)
    @connection.start
    @channel = @connection.create_channel
    @exchange = Bunny::Exchange.new(@channel, exchange_type, exchange_name)
  rescue Bunny::Exception
    raise Error.new("Error connecting to queue")
  end

  def publish(message)
    @exchange.publish(message, routing_key: @routing_key)
  rescue Bunny::Exception
    raise Error.new("Error communicating with queue")
  end
end
