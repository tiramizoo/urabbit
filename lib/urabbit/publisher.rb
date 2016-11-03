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
  def initialize(opts)
    exchange_type = opts[:exchange_type] || :topic
    exchange_name = opts[:exchange_name] ||
      raise(Error.new("Please provide an 'exchange_name'"))
    @routing_key = opts[:routing_key] ||
      raise(Error.new("Please provide a 'routing_key'"))

    @channel = Urabbit.create_channel
    @exchange = Bunny::Exchange.new(
      @channel,
      exchange_type,
      exchange_name,
      durable: true
    )
  rescue Bunny::Exception
    raise Error.new("Error connecting to queue")
  end

  def publish(message)
    @exchange.publish(message, routing_key: @routing_key)
  rescue Bunny::Exception
    raise Error.new("Error communicating with queue")
  end
end
