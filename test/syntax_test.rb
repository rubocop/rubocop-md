# frozen_string_literal: true

require "test_helper"

class RuboCop::Markdown::SyntaxTest < Minitest::Test
  def test_reports_reference_warnings_at_original_locations
    source = "---\ntitle: Example\n---\n\n[label][missing]\n"
    offenses = investigate(source)
    offense = offenses.first

    assert_equal [5], offenses.map(&:line)
    assert_equal 0, offense.column
    assert_equal "[label][missing]", offense.location.source_line
    assert_equal "Markdown/Syntax", offense.cop_name
    assert_equal :warning, offense.severity.name
    refute offense.correctable?
  end

  def test_reports_invalid_html
    offenses = investigate("<div>\n</font>\n</div>\n")

    assert_equal [2], offenses.map(&:line)
    assert_includes offenses.first.message, "invalidly used HTML closing tag"
  end

  def test_ignores_line_numbers_inside_link_labels
    assert_equal [1], investigate("[label][line 999]\n").map(&:line)
  end

  def test_preserves_multiple_warnings_on_the_same_line
    offenses = investigate("[one][missing] and [two][also-missing]\n")

    assert_equal [1], offenses.map(&:line)
    assert_includes offenses.first.message, "link ID 'missing'"
    assert_includes offenses.first.message, "link ID 'also-missing'"
  end

  def test_supports_inline_disabling
    source = <<~MARKDOWN
      <!-- # rubocop:disable Markdown/Syntax -->

      [label][missing]

      <!-- # rubocop:enable Markdown/Syntax -->

      [label][also-missing]
    MARKDOWN

    assert_equal [7], investigate(source).map(&:line)
  end

  def test_unlocated_warnings_are_reported_at_the_start_of_the_file
    source = "A paragraph.\n"
    root, = RuboCop::Markdown::Parser.parse(source)
    warnings = ["A parser warning without a location", "A parser warning refers to line 999"]
    RuboCop::Markdown::Parser.stub(:parse, [root, warnings]) do
      offenses = investigate(source)

      assert_equal [1], offenses.map(&:line)
      assert_equal "A paragraph.", offenses.first.location.source_line
      warnings.each { |warning| assert_includes offenses.first.message, warning }
    end
  end

  def test_ignores_ruby_files
    assert_empty investigate("puts 1\n", file: "test.rb")
  end

  private

  def investigate(source, file: "test.md")
    config = RuboCop::ConfigLoader.merge_with_default(
      RuboCop::Config.new("Markdown/Syntax" => { "Enabled" => true }),
      File.join(__dir__, ".rubocop.yml")
    )
    cop = RuboCop::Cop::Markdown::Syntax.new(config)
    processed = RuboCop::ProcessedSource.new(source, RuboCop::TargetRuby::DEFAULT_VERSION, file)
    processed.config = config
    processed.registry = RuboCop::Cop::Registry.new([cop.class])
    report = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true).investigate(processed)
    report.offenses.reject(&:disabled?)
  end
end
