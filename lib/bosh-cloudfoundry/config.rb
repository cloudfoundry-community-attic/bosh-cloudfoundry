# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; end

module Bosh::CloudFoundry
  class Config

    class << self

      attr_accessor :base_systems_dir

      def configure(config)
        config = deep_merge(load_defaults, config)

        @base_systems_dir = config["base_systems_dir"]
        FileUtils.mkdir_p(@base_systems_dir)

        @logger = Logger.new(config["logging"]["file"] || STDOUT)
        @logger.level = Logger.const_get(config["logging"]["level"].upcase)
        @logger.formatter = ThreadFormatter.new
      end

      private

      def deep_merge(src, dst)
        src.merge(dst) do |key, old, new|
          if new.respond_to?(:blank) && new.blank?
            old
          elsif old.kind_of?(Hash) and new.kind_of?(Hash)
            deep_merge(old, new)
          elsif old.kind_of?(Array) and new.kind_of?(Array)
            old.concat(new).uniq
          else
            new
          end
        end
      end

      def load_defaults
        file = File.join(File.dirname(File.expand_path(__FILE__)), "../../config/defaults.yml")
        YAML.load_file(file)
      end
    end
  end
end
