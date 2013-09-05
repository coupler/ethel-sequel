# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ethel/adapters/sequel/version'

Gem::Specification.new do |gem|
  gem.name          = "ethel-sequel"
  gem.version       = Ethel::Adapters::Sequel::VERSION
  gem.authors       = ["Jeremy Stephens"]
  gem.email         = ["jeremy.f.stephens@vanderbilt.edu"]
  gem.description   = %q{Adds Sequel support to Ethel}
  gem.summary       = %q{Sequel adapter for Ethel}
  gem.homepage      = "https://github.com/coupler/ethel-sequel"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'sequel'
  gem.add_dependency 'ethel'
end
