# frozen_string_literal: true

require "test_helper"
require "open3"
require "fileutils"

module RuboCopRunner
  def run_rubocop(path, options: "", config: nil)
    md_config_path = File.expand_path("./fixtures/.rubocop.yml", __dir__)

    options = "#{options} --plugin rubocop-md" if ENV["MD_LOAD_MODE"] == "options"

    if ENV["MD_LOAD_MODE"] == "config"
      # Add "_with_require" suffix
      config = if config
                 config.sub(/\.yml$/, "_with_require.yml")
               else
                 md_config_path
               end
    end

    options = "#{options} -c #{config}" if config

    output, _status = Open3.capture2(
      "bundle exec rubocop #{options} #{path}",
      chdir: File.join(__dir__, "fixtures")
    )
    output
  end
end

class RuboCop::Markdown::AnalyzeTest < Minitest::Test
  include RuboCopRunner

  def test_file_with_format_options
    res = run_rubocop("single_snippet.md", options: "--format progress")

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{1 offense detected}, res
    assert_match %r{Style/StringLiterals}, res
  end

  def test_rubocop_with_passed_config
    res = run_rubocop(
      "single_snippet.md",
      config: "configs/config.yml"
    )

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{1 offense detected}, res
    assert_match %r{Style/StringLiterals}, res
  end

  def test_with_cache
    res = run_rubocop("single_snippet.md", options: "--cache true")
    assert_match %r{Inspecting 1 file}, res
    assert_match %r{1 offense detected}, res
    assert_includes res, "create(:beatle, name: 'John')"

    res_cached = run_rubocop("single_snippet.md", options: "--cache true")
    assert_includes res_cached, "create(:beatle, name: 'John')"
  end

  def test_file_extensions
    res = run_rubocop("file_extensions/")
    assert_includes res, "file_extensions/01.md:"
    assert_includes res, "file_extensions/02.markdown:"
    assert_includes res, "file_extensions/03.mdown:"
    assert_includes res, "file_extensions/04.mdwn:"
    assert_includes res, "file_extensions/06.mkd:"
    assert_includes res, "file_extensions/07.mkdn:"
    assert_includes res, "file_extensions/08.mkdown:"
    assert_includes res, "file_extensions/09.ronn:"
    assert_includes res, "file_extensions/10.workbook:"
    assert_includes res, "file_extensions/11.livemd:"
    assert_includes res, "file_extensions/12.scd:"
  end
end
