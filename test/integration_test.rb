# frozen_string_literal: true

require "test_helper"
require "open3"
require "fileutils"
require "tmpdir"

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

  def test_parser_based_autocorrection
    Dir.mktmpdir("rubocop-md") do |directory|
      config = File.join(directory, ".rubocop.yml")
      File.write(config, <<~YAML)
        plugins:
          - rubocop-md
        AllCops:
          NewCops: enable
          SuggestExtensions: false
        Style/StringLiterals:
          EnforcedStyle: double_quotes
      YAML
      source = <<~MARKDOWN
        First paragraph
        stays wrapped.

        ```ruby example
        puts 'hello'
        ```

        > ~~~ruby
        > puts 'quoted'
        > ~~~

        - Example:

          `````ruby
          puts 'listed'
          `````

        # Indented

            puts 'indented'
      MARKDOWN
      expected = source.gsub(/'(hello|quoted|listed|indented)'/, '"\1"')
      file = File.join(directory, "example.md")
      File.write(file, source)
      arguments = ["bundle", "exec", "rubocop", "--config", config, "--cache", "false", "-a"]
      output, status = Open3.capture2e(*arguments, file)

      assert status.success?, output
      assert_equal expected, File.read(file)
      output, status = Open3.capture2e(*arguments, file)
      assert status.success?, output
      assert_includes output, "no offenses detected"

      stdin_source = "> ~~~ruby\n> puts 'stdin'\n> ~~~\n"
      output, status = Open3.capture2e(*arguments, "--stdin", file, stdin_data: stdin_source)
      assert status.success?, output
      assert_includes output, "> puts \"stdin\""
      refute_includes output, RuboCop::Markdown::Preprocess::MARKER
      assert_equal expected, File.read(file)
    end
  end

  def test_prose_cop_can_read_and_correct_the_original_buffer_alongside_ruby_cops
    Dir.mktmpdir("rubocop-md") do |directory|
      File.write(File.join(directory, "prose.rb"), <<~RUBY)
        module RuboCop
          module Cop
            module BufferTest
              class Prose < Base
                extend AutoCorrector

                def on_new_investigation
                  buffer = processed_source.markdown_document.buffer
                  source = buffer.source
                  position = source.index("wrld")
                  return unless position

                  range = Parser::Source::Range.new(buffer, position, position + 4)
                  mapped = processed_source.markdown_document.processed_range(range)
                  add_offense(mapped, message: "Use world.") do |corrector|
                    corrector.replace(range, "world")
                  end
                end
              end
            end
          end
        end
      RUBY
      File.write(File.join(directory, ".rubocop.yml"), <<~YAML)
        plugins:
          - rubocop-md
        require:
          - ./prose.rb
        AllCops:
          NewCops: enable
          SuggestExtensions: false
        BufferTest/Prose:
          Enabled: true
        Style/StringLiterals:
          EnforcedStyle: double_quotes
      YAML
      source = "😀 wrld\n\n> ```ruby\n> puts 'hello'\n> ```\n"
      file = File.join(directory, "example.md")
      File.write(file, source)
      command = ["bundle", "exec", "rubocop", "--cache", "false", "--only",
                 "BufferTest/Prose,Style/StringLiterals"]
      output, status = Open3.capture2e(*command, "--format", "json", file, chdir: directory)
      assert_equal 1, status.exitstatus, output
      offenses = JSON.parse(output).fetch("files").first.fetch("offenses")
      prose = offenses.find { |offense| offense.fetch("cop_name") == "BufferTest/Prose" }
      assert_equal 3, prose.fetch("location").fetch("start_column")
      assert_equal 1, prose.fetch("location").fetch("start_line")

      expected = "😀 world\n\n> ```ruby\n> puts \"hello\"\n> ```\n"
      2.times do
        output, status = Open3.capture2e(*command, "-A", file, chdir: directory)
        assert status.success?, output
        assert_equal expected, File.read(file)
      end
      output, status = Open3.capture2e(*command, "-A", "--stdin", file, stdin_data: source, chdir: directory)
      assert status.success?, output
      assert_includes output, expected
      refute_includes output, RuboCop::Markdown::Preprocess::MARKER
    end
  end
end
