module RuboCop
  module Markdown # :nodoc:
    # Merge markdown config into default configuration
    # See https://github.com/backus/rubocop-rspec/blob/master/lib/rubocop/rspec/inject.rb
    def self.inject!
      path = CONFIG_DEFAULT.to_s
      hash = ConfigLoader.send(:load_yaml_configuration, path)
      config = Config.new(hash, path)
      puts "configuration from #{path}" if ConfigLoader.debug?
      config = ConfigLoader.merge_with_default(config, path)
      ConfigLoader.instance_variable_set(:@default_configuration, config)
    end
  end
end

RuboCop::Markdown.inject!

# Allow Rubocop to analyze markdown files
RuboCop::TargetFinder.prepend(Module.new do
  MARKDOWN_EXTENSIONS = %w[.md .markdown].freeze

  def ruby_file?(file)
    super || markdown_file?(file)
  end

  def markdown_file?(file)
    MARKDOWN_EXTENSIONS.include?(File.extname(file))
  end
end)

# Extend ProcessedSource#parse with pre-processing
RuboCop::ProcessedSource.prepend(Module.new do
  def parse(src, *args)
    src = RuboCop::Markdown::Preprocess.call(src)
    super(src, *args)
  end
end)
