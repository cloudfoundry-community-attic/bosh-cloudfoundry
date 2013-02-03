# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bosh-cloudfoundry/version'

Gem::Specification.new do |gem|
  gem.name          = "bosh-cloudfoundry"
  gem.version       = Bosh::Cloudfoundry::VERSION
  gem.authors       = ["Dr Nic Williams"]
  gem.email         = ["drnicwilliams@gmail.com"]
  gem.description   = %q{Create and manage your Cloud Foundry deployments}
  gem.summary       = %q{Create and manage your Cloud Foundry deployments via the BOSH CLI}
  gem.homepage      = "https://github.com/StarkAndWayne/bosh-cloudfoundry"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "bosh_cli", ">=1.0.3"
  gem.add_dependency "rake" # file_utils sh helper
  gem.add_dependency "net-dns"
  gem.add_dependency "fog", ">= 1.8.0"
  gem.add_development_dependency "rspec"
end
