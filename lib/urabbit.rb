require "bunny"
require "logger"
require "json"
require "securerandom"

require "urabbit/version"
require "urabbit/rpc"
require "urabbit/rpc/server"
require "urabbit/rpc/client"
require "urabbit/publisher"

module Urabbit
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
end
