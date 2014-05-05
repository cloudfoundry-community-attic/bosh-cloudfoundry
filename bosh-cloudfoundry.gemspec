# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "bosh-cloudfoundry"
  spec.version       = "0.7.6"
  spec.authors       = ["Dr Nic Williams"]
  spec.email         = ["drnicwilliams@gmail.com"]
  spec.description   = %q{Create & manage Cloud Foundry deployments}
  spec.summary       = %q{Create & manage Cloud Foundry deployments using bosh in AWS & OpenStack}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "bosh_cli"
  spec.add_dependency "net-dns"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec", "~> 2.13.0"
  spec.add_development_dependency "rspec-fire"
  spec.add_development_dependency "fakeweb"
end
