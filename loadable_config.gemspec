# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'loadable_config/version'

Gem::Specification.new do |spec|
  spec.name          = "loadable_config"
  spec.version       = LoadableConfig::VERSION
  spec.authors       = ["iKnow Team"]
  spec.email         = ["dev@iknow.jp"]

  spec.summary       = %q{Simple declarative configuration files}
  spec.homepage      = "http://github.com/iknow/loadable_config"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "json_schema"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
