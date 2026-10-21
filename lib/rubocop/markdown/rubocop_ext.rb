# frozen_string_literal: true

module RuboCop
  module Markdown # :nodoc:
    # See https://github.com/github-linguist/linguist/blob/8c380f360ce00b95fa08d14ce0ebccd481af1b33/lib/linguist/languages.yml#L4088-L4098
    # Keep in sync with config/default.yml
    MARKDOWN_EXTENSIONS = %w[
      .md
      .livemd
      .markdown
      .mdown
      .mdwn
      .mkd
      .mkdn
      .mkdown
      .ronn
      .scd
      .workbook
    ].freeze

    # A list of cops that could produce offenses in commented lines
    MARKDOWN_OFFENSE_COPS = %w[Lint/Syntax].freeze

    class << self
      attr_accessor :config_store

      def markdown_file?(file)
        MARKDOWN_EXTENSIONS.include?(File.extname(file))
      end

      def ignored_offense?(cop_name, location)
        return false if MARKDOWN_OFFENSE_COPS.include?(cop_name)
        return false if location.is_a?(Document::ProseRange)

        location.source_line.start_with?("##{Preprocess::MARKER}")
      end
    end
  end
end

RuboCop::Runner.prepend(Module.new do
  # Set config store for Markdown
  def get_processed_source(...)
    RuboCop::Markdown.config_store = @config_store unless RuboCop::Markdown.config_store

    super
  end

  # Only cache markdown files if they have no offenses, 'cause cache doesn't know about processing.
  # NOTE: we should involve preprocessing in RuboCop::CachedData#deserialize_offenses
  def file_offense_cache(file, ...)
    if cached_run? && RuboCop::Markdown.markdown_file?(file)
      config = @config_store.for_file(file)
      cache = cached_result(file, standby_team(config))

      if cache&.valid?
        offenses = cache.load

        real_run_needed = offenses.any?
      else
        real_run_needed = true
      end

      if real_run_needed
        offenses = yield
        save_in_cache(cache, offenses) if offenses.empty?
      end

      offenses
    else
      super
    end
  end
end)

RuboCop::Cop::Base.prepend(Module.new do
  def add_offense(node_or_range, **options, &block)
    location = range_from_node_or_range(node_or_range)
    return if RuboCop::Markdown.ignored_offense?(cop_name, location)

    super
  end

  private

  def range_for_original(range)
    document = processed_source.markdown_document
    document ? document.original_range(range) : super
  end
end)

RuboCop::Cop::Corrector.prepend(Module.new do
  def initialize(source)
    processed = source.respond_to?(:processed_source) ? source.processed_source : source
    @markdown_document = processed.markdown_document if processed.respond_to?(:markdown_document)
    super(@markdown_document ? @markdown_document.processed_buffer : source)
  end

  def rewrite
    @markdown_document ? @markdown_document.corrected_source(self) : super
  end

  private

  def to_range(node_or_range)
    if @markdown_document && node_or_range.is_a?(Parser::Source::Range) &&
       node_or_range.source_buffer.equal?(@markdown_document.buffer)
      node_or_range = @markdown_document.processed_range(node_or_range)
    end
    super
  end
end)

RuboCop::Cop::Commissioner::InvestigationReport.prepend(Module.new do
  # Skip offenses reported for ignored MD source (trailing whitespaces, etc.)
  def offenses
    @offenses ||= offenses_per_cop.flatten(1).reject do |offense|
      RuboCop::Markdown.ignored_offense?(offense.cop_name, offense.location)
    end
  end
end)

# Allow Rubocop to analyze markdown files
RuboCop::TargetFinder.prepend(Module.new do
  def ruby_file?(file, ...)
    super || RuboCop::Markdown.markdown_file?(file)
  end
end)

# Extend ProcessedSource#parse with pre-processing
RuboCop::ProcessedSource.prepend(Module.new do
  attr_reader :markdown_document

  def parse(src, ...)
    # only process Markdown files
    if path && RuboCop::Markdown.markdown_file?(path)
      @markdown_document = RuboCop::Markdown::Document.new(src, path)
      src = RuboCop::Markdown::Preprocess.new(path).call(src, document: @markdown_document)
    end
    super
    @markdown_document.processed_buffer = @buffer if @markdown_document
  end
end)
