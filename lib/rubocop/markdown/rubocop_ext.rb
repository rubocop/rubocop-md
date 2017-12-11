module RuboCop
  module Markdown # :nodoc:
    MARKDOWN_EXTENSIONS = %w[.md .markdown].freeze

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

    def self.markdown_file?(file)
      MARKDOWN_EXTENSIONS.include?(File.extname(file))
    end
  end
end

RuboCop::Markdown.inject!

# Do not cache markdown files, 'cause cache doesn't know about processing.
# NOTE: we should involve preprocessing in RuboCop::CachedData#deserialize_offenses
RuboCop::Runner.prepend(Module.new do
  def file_offense_cache(file)
    return yield if RuboCop::Markdown.markdown_file?(file)
    super
  end
end)

# Allow Rubocop to analyze markdown files
RuboCop::TargetFinder.prepend(Module.new do
  def ruby_file?(file)
    super || RuboCop::Markdown.markdown_file?(file)
  end
end)

# Extend ProcessedSource#parse with pre-processing
RuboCop::ProcessedSource.prepend(Module.new do
  def parse(src, *args)
    # only process Markdown files
    src = RuboCop::Markdown::Preprocess.call(src) if
      path.nil? || RuboCop::Markdown.markdown_file?(path)
    super(src, *args)
  end
end)
