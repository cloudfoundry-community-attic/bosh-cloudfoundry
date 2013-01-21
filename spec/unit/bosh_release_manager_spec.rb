# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::BoshReleaseManager do
  include Bosh::CloudFoundry::BoshReleaseManager
  include FileUtils
end
