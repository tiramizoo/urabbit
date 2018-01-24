# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'urabbit/version'

Gem::Specification.new do |spec|
  spec.name          = "urabbit"
  spec.version       = Urabbit::VERSION
  spec.authors       = ["Jacek Becela"]
  spec.email         = ["jacek.becela@gmail.com"]

  spec.summary       = %q{A small microservices library using RabbitMQ}
  spec.homepage      = "https://github.com/ncr/urabbit"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_dependency "bunny", "~> 2.8"
  spec.add_dependency "sneakers"
  spec.add_dependency "sneakers_handlers"
end
