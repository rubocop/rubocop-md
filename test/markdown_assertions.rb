# frozen_string_literal: true

require "fileutils"

module RuboCop
  module Markdown
    # Necessary overwrites over rubocop minitest assertions to run all cops and handle markdown autocorrection
    class Test < Minitest::Test
      include AssertOffense

      class DummyCop
        def initialize
          @options = {}
        end
      end

      # Lint/Syntax has a multiline offense which is impossible to match against
      class RuboCop::Cop::Lint::Syntax
        def add_offense_from_diagnostic(diagnostic, _ruby_version)
          add_offense(diagnostic.location, message: diagnostic.message, severity: diagnostic.level)
        end
      end

      def assert_offense(source, file = "test.md", **replacements)
        @cop = DummyCop.new
        super
      end

      def assert_no_offenses(source, file = "test.md")
        super
      end

      # rubocop:disable Metrics/AbcSize
      def assert_correction(correction, loop: true)
        raise "`assert_correction` must follow `assert_offense`" unless @processed_source

        iteration = 0
        new_source = loop do
          iteration += 1

          corrected_source = @last_corrector.rewrite

          break corrected_source unless loop
          if @last_corrector.empty? || corrected_source == @processed_source.buffer.source
            break corrected_source
          end

          if iteration > RuboCop::Runner::MAX_ITERATIONS
            raise RuboCop::Runner::InfiniteCorrectionLoop.new(@processed_source.path, [])
          end

          # Prepare for next loop
          RuboCop::Markdown::Preprocess.restore!(corrected_source)
          @processed_source = parse_source!(corrected_source)

          _investigate(@cop, @processed_source)
        end

        RuboCop::Markdown::Preprocess.restore!(new_source)

        assert_equal(correction, new_source)
      ensure
        FileUtils.rm_f(@processed_source.path)
      end
      # rubocop:enable Metrics/AbcSize

      def investigate(_cop, processed_source)
        commissioner = RuboCop::Cop::Commissioner.new(registry.cops, registry.class.forces_for(registry.cops), raise_error: true)
        commissioner.investigate(processed_source)
        commissioner
      end

      def _investigate(_cop, processed_source)
        team = RuboCop::Cop::Team.mobilize(registry.cops, configuration, raise_error: true, autocorrect: true)
        report = team.investigate(processed_source)
        @last_corrector = report.correctors.compact.first || RuboCop::Cop::Corrector.new(processed_source)
        report.offenses
      end

      def inspect_source(source, cop, file = "test.md")
        super
      end

      def parse_source!(source, file = "test.md")
        super
      end

      def config
        project_config_path = RuboCop::Markdown::PROJECT_ROOT.join(".rubocop.yml").to_s
        project_config = RuboCop::ConfigLoader.load_file(project_config_path)
        test_config = RuboCop::Config.new(project_config.merge(@config || {}))
        RuboCop::ConfigLoader.merge_with_default(test_config, project_config_path)
      end
    end
  end
end
