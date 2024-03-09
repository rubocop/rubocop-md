# frozen_string_literal: true

require "rubocop/rspec/expect_offense"

module RuboCop
  module Markdown
    class Test < Minitest::Test
      # Lint/Syntax has a multiline offense which is impossible to match against
      class RuboCop::Cop::Lint::Syntax
        def add_offense_from_diagnostic(diagnostic, _ruby_version)
          add_offense(diagnostic.location, message: diagnostic.message, severity: diagnostic.level)
        end
      end

      def assert_offense(source, file = "test.md")
        expected_annotations = RuboCop::RSpec::ExpectOffense::AnnotatedSource.parse(source)
        @original_processed_source = parse_source(expected_annotations.plain_source, file)
        @team, offenses = _investigate(@original_processed_source)

        actual_annotations = expected_annotations.with_offense_annotations(offenses)
        assert_equal(expected_annotations, actual_annotations)
      end

      # rubocop:disable Metrics/AbcSize
      def assert_correction(source)
        raise "`assert_correction` must follow `assert_offense`" unless @original_processed_source
        if autocorrect_from_team(@original_processed_source) == @original_processed_source.raw_source
          raise "Use `expect_no_corrections` if the code will not change"
        end

        iteration = 0
        processed_source = @original_processed_source
        new_source = loop do
          iteration += 1

          corrected_source = autocorrect_from_team(processed_source)

          break corrected_source if corrected_source == processed_source.buffer.source

          if iteration > RuboCop::Runner::MAX_ITERATIONS
            raise RuboCop::Runner::InfiniteCorrectionLoop.new(processed_source.path, [@offenses])
          end

          # Prepare for next loop
          processed_source = parse_source(corrected_source, processed_source.path)
          @team, _offenses = _investigate(processed_source)
        end

        assert_equal(source, new_source)
      end
      # rubocop:enable Metrics/AbcSize

      def autocorrect_from_team(processed_source)
        autocorrect = @team.instance_variable_get(:@options)[:stdin]
        if autocorrect == true
          # stdin wasn't modified. No autocorrect took place, return previous source
          processed_source.buffer.source
        else
          autocorrect
        end
      end

      def assert_no_offenses(source, file = "test.md")
        original_processed_source = parse_source(source, file)
        _team, offenses = _investigate(original_processed_source)

        expected_annotations = RuboCop::RSpec::ExpectOffense::AnnotatedSource.parse(source)
        actual_annotations = expected_annotations.with_offense_annotations(offenses)
        assert_equal(expected_annotations, actual_annotations)
      end

      def _investigate(original_processed_source)
        # stdin: true will put the autocorrection in the stdin option for later use
        team = RuboCop::Cop::Team.new(registry.cops, config, raise_error: true, autocorrect: true, stdin: true)
        extracted_ruby_sources = Markdown::RubyExtractor.new(original_processed_source).call || []

        investigations = extracted_ruby_sources.flat_map do |extracted_ruby_source|
          team.investigate(
            extracted_ruby_source[:processed_source],
            offset: extracted_ruby_source[:offset],
            original: original_processed_source
          )
        end
        [team, investigations.map(&:offenses).flatten]
      end

      def parse_source(source, file)
        processed_source = RuboCop::ProcessedSource.new(source, ruby_version, file)
        processed_source.config = config
        processed_source.registry = registry
        processed_source
      end

      def config
        @config ||= begin
          project_config_path = RuboCop::Markdown::PROJECT_ROOT.join(".rubocop.yml").to_s
          project_config = RuboCop::ConfigLoader.load_file(project_config_path)
          test_config = RuboCop::Config.new(project_config.merge(@config || {}))
          RuboCop::ConfigLoader.merge_with_default(test_config, project_config_path)
        end
      end

      def registry
        @registry ||= begin
          cops = config.keys.map { |cop| RuboCop::Cop::Registry.global.find_by_cop_name(cop) }
          cops << cop_class if defined?(cop_class) && !cops.include?(cop_class)
          cops.compact!
          RuboCop::Cop::Registry.new(cops)
        end
      end

      def ruby_version
        RuboCop::TargetRuby::DEFAULT_VERSION
      end
    end
  end
end
