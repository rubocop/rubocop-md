# frozen_string_literal: true

require "test_helper"
require "open3"
require "fileutils"

module RuboCopRunner
  def run_rubocop(path, options: "")
    md_path = File.expand_path("../lib/rubocop-md.rb", __dir__)
    output, _status = Open3.capture2(
      "bundle exec rubocop -r #{md_path} #{options} #{path}",
      chdir: File.join(__dir__, "fixtures")
    )
    output
  end
end

class RuboCop::Markdown::AnalyzeTest < Minitest::Test
  include RuboCopRunner

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
    assert_match %r{Lint/Syntax: unexpected token}, res
  end

  def test_multiple_invalid_snippets_file_no_warn
    res = run_rubocop(
      "multiple_invalid_snippets.md",
      options: "-c configs/no_warn_invalid.yml"
    )

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{no offenses detected}, res
  end

  def test_multiple_invalid_snippets_file_no_autodetect
    res = run_rubocop(
      "multiple_invalid_snippets_unknown.md",
      options: "-c configs/no_autodetect.yml"
    )

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{no offenses detected}, res
  end

  def test_with_cache
    res = run_rubocop("multiple_snippets.markdown", options: "--cache true")
    assert_match %r{Inspecting 1 file}, res
    assert_match %r{4 offenses detected}, res
    assert_includes res, 'have_header("X-TOTAL-PAGES",10)'

    res_cached = run_rubocop("multiple_snippets.markdown", options: "--cache true")
    assert_includes res_cached, 'have_header("X-TOTAL-PAGES",10)'
  end
end

class RuboCop::Markdown::AutocorrectTest < Minitest::Test
  using SquigglyHeredoc
  include RuboCopRunner

  def fixture_name
    @fixture_name ||= "autocorrect_test.md"
  end

  def fixture_file
    @fixture_file ||= File.join(__dir__, "fixtures", fixture_name)
  end

  def prepare_test(contents)
    File.write(fixture_file, contents)
  end

  def teardown
    FileUtils.rm(fixture_file)
  end

  def test_autocorrect_single_snippet
    prepare_test(
      <<-CODE.squiggly
        # Before All

        Rails has a great feature – `transactional_tests`.

        We can do something like this:

        ```ruby
        describe BeatleWeightedSearchQuery do
          before(:each) do
            @paul = create(:beatle, name: "Paul")
            @john = create(:beatle, name: 'John')
          end

          # and about 15 examples here
        end
        ```
      CODE
    )

    expected = <<-CODE.squiggly
      # Before All

      Rails has a great feature – `transactional_tests`.

      We can do something like this:

      ```ruby
      describe BeatleWeightedSearchQuery do
        before(:each) do
          @paul = create(:beatle, name: "Paul")
          @john = create(:beatle, name: "John")
        end

        # and about 15 examples here
      end
      ```
    CODE

    res = run_rubocop(fixture_name, options: "-a")
    assert_match %r{1 offense detected}, res
    assert_match %r{1 offense corrected}, res

    assert_equal expected, File.read(fixture_file)
  end

  def test_autocorrect_multiple_snippets
    prepare_test(
      <<-CODE.squiggly
        ```ruby
        # bad
        it { is_expected.to be_success }
        it { is_expected.to have_header("X-TOTAL-PAGES",10) }
        it {is_expected.to have_header("X-NEXT-PAGE", 2)}
        ```

        That's the better way:

        ```
        # good
        it "returns the second page",:aggregate_failures do
          is_expected.to be_success
          is_expected.to have_header("X-TOTAL-PAGES", 10)
          is_expected.to have_header("X-NEXT-PAGE", 2)
        end
        ```

        To enable them:

        - Require `test_prof/rubocop` in your RuboCop configuration:

        ```yml
        # .rubocop.yml
        require:
         - 'test_prof/rubocop'
        ```
      CODE
    )

    expected = <<-CODE.squiggly
      ```ruby
      # bad
      it { is_expected.to be_success }
      it { is_expected.to have_header("X-TOTAL-PAGES", 10) }
      it { is_expected.to have_header("X-NEXT-PAGE", 2) }
      ```

      That's the better way:

      ```
      # good
      it "returns the second page", :aggregate_failures do
        is_expected.to be_success
        is_expected.to have_header("X-TOTAL-PAGES", 10)
        is_expected.to have_header("X-NEXT-PAGE", 2)
      end
      ```

      To enable them:

      - Require `test_prof/rubocop` in your RuboCop configuration:

      ```yml
      # .rubocop.yml
      require:
       - 'test_prof/rubocop'
      ```
    CODE

    res = run_rubocop(fixture_name, options: "-a")
    assert_match %r{4 offenses detected}, res
    assert_match %r{4 offenses corrected}, res

    assert_equal expected, File.read(fixture_file)
  end
end
