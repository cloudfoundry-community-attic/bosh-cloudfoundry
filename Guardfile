guard 'rspec', spec_paths: ["spec"] do
  watch(%r{^spec/(.+_spec)\.rb$})
  watch(%r{^lib/bosh/cli/commands/(.+)\.rb$})    { |m| "spec/plugin_spec.rb" }
  watch(%r{^lib/bosh/cloudfoundry/(.+)\.rb$})    { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

