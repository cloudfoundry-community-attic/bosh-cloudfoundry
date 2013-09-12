# Copyright (c) 2012-2013 Stark & Wayne, LLC

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

require "rubygems"
require "bundler"
Bundler.setup(:default, :test)

$:.unshift(File.expand_path("../../lib", __FILE__))

def latest_cf_release_version
  136
end

require "rspec/core"
require 'rspec/fire'

require "tmpdir"

# for the #sh helper
require "rake"
require "rake/file_utils"

# bosh_cli
require "cli"

require "bosh/cloudfoundry"

require "fakeweb"
FakeWeb.allow_net_connect = false

RSpec.configure do |config|
  config.include(RSpec::Fire)
end

# load all files in spec/support/* (but not lower down)
Dir[File.dirname(__FILE__) + '/support/*'].each do |path|
  require path unless File.directory?(path)
end

def spec_asset(filename)
  File.expand_path("../assets/#{filename}", __FILE__)
end

def files_match(filename, expected_filename)
  file = File.read(filename)
  expected_file = File.read(expected_filename)
  file.should == expected_file
end

def yaml_files_match(filename, expected_filename)
  yaml = YAML.load_file(filename)
  expected_yaml = YAML.load_file(expected_filename)
  yaml.should == expected_yaml
end

def setup_home_dir
  home_dir = File.expand_path("../../tmp/home", __FILE__)
  FileUtils.rm_rf(home_dir)
  FileUtils.mkdir_p(home_dir)
  ENV['HOME'] = home_dir
end

# returns the file path to a file
# in the fake $HOME folder
def home_file(*path)
  File.join(ENV['HOME'], *path)
end

def in_home_dir(&block)
  FileUtils.chdir(home_file, &block)
end

def get_tmp_file_path(content)
  tmp_file = File.open(File.join(Dir.mktmpdir, "tmp"), "w")
  tmp_file.write(content)
  tmp_file.close

  tmp_file.path
end
