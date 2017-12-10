require "test_helper"
require "open3"

class RuboCop::Markdown::IntegrationTest < Minitest::Test
  def run_rubocop(path, options: "")
    md_path = File.expand_path("../../lib/rubocop-md.rb", __FILE__)
    output, _status = Open3.capture2(
      "bundle exec rubocop -r #{md_path} #{options} #{path}",
      chdir: File.join(__dir__, "fixtures")
    )
    output
  end

  def test_single_snippet_file
    res = run_rubocop("single_snippet.md")

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{1 offense detected}, res
    assert_match %r{Style/StringLiterals}, res
  end

  def test_multiple_snippets_file
    res = run_rubocop("multiple_snippets.markdown")

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{4 offenses detected}, res
    assert_match %r{Layout/SpaceAfterComma}, res
    assert_match %r{Layout/SpaceInsideBlockBraces}, res
  end

  def test_multiple_invalid_snippets_file
    res = run_rubocop("multiple_invalid_snippets.md")

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{no offenses detected}, res
  end
end
