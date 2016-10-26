require 'test_helper'


class RPCTestServer
  include Urabbit::RPC::Server

  from_queue 'rpc.test'

  def work(message)
    JSON.generate(JSON.parse(message))
  end
end

class RPCServerTest < Minitest::Test
  def setup
    Urabbit.connect
    # Shorter delay when server is stopped in tests.
    Urabbit::RPC::Server.const_set(:SleepInterval, 0.01)

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

    assert_raises(Urabbit::Error) do
      rpc_client.call('rpc.test', 'not a json')
    end
  end

  def test_when_RPC_server_is_down
    rpc_client = Urabbit::RPC::Client.new

    assert_raises(Urabbit::Error) do
      # Setting a short timeout for tests.
      rpc_client.call('non-existent-routing-key', 'message', 0.1)
    end
  end

  def test_responds_to_requests
    rpc_client = Urabbit::RPC::Client.new

    result = JSON.parse(
      rpc_client.call('rpc.test', {"key" => "value"}.to_json)
    )

    assert_equal({"key" => "value"}, result)
  end
end
