source 'https://rubygems.org'

# Specify your gem's dependencies in redis-cf-plugin.gemspec
gemspec

path = File.expand_path("~/gems/cloudfoundry/bosh/bosh_cli")
if File.directory?(path)
  gem "bosh_cli", path: path
end

path = File.expand_path("~/gems/bosh-verifyconnections")
if File.directory?(path)
  gem "bosh-verifyconnections", path: path
else
  gem "bosh-verifyconnections"
end

group :development do
  gem "guard-rspec"
end
