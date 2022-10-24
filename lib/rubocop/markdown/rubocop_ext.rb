# frozen_string_literal: true

module RuboCop
  module Markdown # :nodoc:
    # According to Linguist.
    # See https://github.com/github/linguist/blob/96ca71ab99c2f9928d5d69f4c08fd2a51440d045/lib/linguist/languages.yml#L3065-L3083
    MARKDOWN_EXTENSIONS = %w[
      .md
      .markdown
      .mdown
      .mdwn
      .mdx
      .mkd
      .mkdn
      .mkdown
      .ronn
      .workbook
    ].freeze

    class << self
      attr_accessor :config_store

      # Merge markdown config into default configuration
      # See https://github.com/backus/rubocop-rspec/blob/master/lib/rubocop/rspec/inject.rb
      def inject!
        path = CONFIG_DEFAULT.to_s
        hash = ConfigLoader.send(:load_yaml_configuration, path)
        config = Config.new(hash, path)
        puts "configuration from #{path}" if ConfigLoader.debug?
        config = ConfigLoader.merge_with_default(config, path)
        ConfigLoader.instance_variable_set(:@default_configuration, config)
      end

      def markdown_file?(file)
        MARKDOWN_EXTENSIONS.include?(File.extname(file))
      end
    end
  end
end

RuboCop::Markdown.inject!

RuboCop::Runner.prepend(Module.new do
  # Set config store for Markdown
  def initialize(*args)
    super
    RuboCop::Markdown.config_store = @config_store
  end

  # Do not cache markdown files, 'cause cache doesn't know about processing.
  # NOTE: we should involve preprocessing in RuboCop::CachedData#deserialize_offenses
  def file_offense_cache(file)
    return yield if RuboCop::Markdown.markdown_file?(file)

    super
  end

  def inspect_file(*args)
    super.tap do |(offenses, *)|
      # Skip offenses reported for ignored MD source (trailing whitespaces, etc.)
      marker_comment = "##{RuboCop::Markdown::Preprocess::MARKER}"
      offenses.reject! do |offense|
        offense.location.source_line.start_with?(marker_comment)
      end
    end
  end

  def file_finished(file, offenses)
    return super unless RuboCop::Markdown.markdown_file?(file)

    # Run Preprocess.restore if file has been autocorrected
    if @options[:auto_correct] || @options[:autocorrect]
      RuboCop::Markdown::Preprocess.restore!(file)
    end

    super(file, offenses)
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
    src = RuboCop::Markdown::Preprocess.new(path).call(src) if
      path && RuboCop::Markdown.markdown_file?(path)
    super(src, *args)
  end
end)
