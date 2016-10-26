require 'test_helper'

class RPCTestServer
  include Urabbit::RPC::Server

  from_queue 'rpc.test'

  def work(message)
    JSON.generate(JSON.parse(message))
  end
end

class RPCTest < Minitest::Test
  def setup
    @rpc_server = RPCTestServer.new
    @server_thread = Thread.new do
      @rpc_server.start
    end
  end

  def teardown
    @rpc_server.stop
    @server_thread.join
  end

  def test_responds_to_malformed_requests_with_an_exception
    rpc_client = Urabbit::RPC::Client.new

    assert_raises(Urabbit::RPC::Client::Error) do
      rpc_client.call('rpc.test', 'not a json')
    end
  end

  def test_responds_to_requests
    rpc_client = Urabbit::RPC::Client.new

    result = JSON.parse(
      rpc_client.call('rpc.test', {"key" => "value"}.to_json)
    )

    assert_equal({"key" => "value"}, result)
  end

  def test_when_RabbitMQ_server_is_down
    assert_raises(Urabbit::RPC::Client::Error) do
      # Connecting to a non-existent server
      Urabbit::RPC::Client.new("amqp://localhost:6666")
    end
  end

  def test_when_RPC_server_is_down
    rpc_client = Urabbit::RPC::Client.new

    assert_raises(Urabbit::RPC::Client::Error) do
      # Setting a short timeout for tests.
      rpc_client.call('non-existent-routing-key', 'message', 0.1)
    end
  end

  def test_an_exception_contains_a_cause
    begin
      Urabbit::RPC::Client.new("amqp://localhost:6666")
    rescue Urabbit::RPC::Client::Error => e
      cause = e.cause
    end

    assert_equal Bunny::TCPConnectionFailedForAllHosts, cause.class
  end
end
