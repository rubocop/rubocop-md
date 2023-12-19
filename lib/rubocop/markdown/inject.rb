# frozen_string_literal: true

module RuboCop
  module Markdown
    # Merge markdown config into default configuration
    # See https://github.com/rubocop/rubocop-rspec/blob/master/lib/rubocop/rspec/inject.rb
    module Inject # :nodoc:
      def self.defaults!
        path = CONFIG_DEFAULT.to_s
        hash = ConfigLoader.send(:load_yaml_configuration, path)
        config = RuboCop::Config.new(hash, path)
        puts "configuration from #{path}" if ConfigLoader.debug?
        config = ConfigLoader.merge_with_default(config, path)
        ConfigLoader.instance_variable_set(:@default_configuration, config)
      end
    end
  end
end
