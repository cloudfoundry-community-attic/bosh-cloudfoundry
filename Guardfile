# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/bosh/cli/commands/cf.rb$})    { |m| "spec/unit/cf_command_spec.rb" }
  watch(%r{^lib/bosh-cloudfoundry/(.+)\.rb$}) { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

