require 'test_helper'

class RPCTest < Minitest::Test
  def test_when_RabbitMQ_is_down_and_exception_contains_a_cause
    begin
      Urabbit.connect("amqp://localhost:6666")
    rescue Urabbit::Error => exception
      cause = exception.cause
    end

    assert_equal Urabbit::Error, exception.class
    assert_equal Bunny::TCPConnectionFailedForAllHosts, cause.class
  end
end
