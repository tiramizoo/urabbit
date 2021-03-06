require "bunny"
require "logger"
require "json"
require "securerandom"

module Urabbit
  class Error < Exception; end
  @mutex = Mutex.new

  def self.logger
    @logger ||= if defined?(Rails)
      Rails.logger
    else
      Logger.new(STDOUT)
    end
  end

  def self.logger=(logger)
    @logger = logger
  end

  # A single connection shared between threads.
  def self.connection(cloudamqp_url = ENV["CLOUDAMQP_URL"])
    @mutex.synchronize do
      @connection ||= begin
        connection = Bunny.new(cloudamqp_url, logger: logger)
        connection.start
        connection
      rescue Bunny::Exception
        raise Error.new("Error connecting to RabbitMQ")
      end
    end
  end

  def self.disconnect
    @connection = nil
  end

  def self.create_channel
    connection.create_channel
  end
end

require "urabbit/version"
require "urabbit/rpc"
require "urabbit/rpc/server"
require "urabbit/rpc/client"
require "urabbit/publisher"
