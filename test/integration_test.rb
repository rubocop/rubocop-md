# frozen_string_literal: true

require "test_helper"
require "open3"
require "fileutils"

module RuboCopRunner
  def run_rubocop(path, options: "", config: nil)
    md_path = File.expand_path("../lib/rubocop-md.rb", __dir__)
    md_config_path = File.expand_path("./fixtures/.rubocop.yml", __dir__)

    options = "#{options} -r #{md_path}" if ENV["MD_LOAD_MODE"] == "options"

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

  def test_single_snippet_file
    res = run_rubocop("single_snippet.md")

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{1 offense detected}, res
    assert_match %r{Style/StringLiterals}, res
  end

  def test_file_with_format_options
    res = run_rubocop("single_snippet.md", options: "--format progress")

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
      config: "configs/no_warn_invalid.yml"
    )

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{no offenses detected}, res
  end

  def test_multiple_invalid_snippets_file_no_autodetect
    res = run_rubocop(
      "multiple_invalid_snippets_unknown.md",
      config: "configs/no_autodetect.yml"
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

  def test_file_extensions
    res = run_rubocop("file_extensions/")
    assert_includes res, "file_extensions/01.md:"
    assert_includes res, "file_extensions/02.markdown:"
    assert_includes res, "file_extensions/03.mdown:"
    assert_includes res, "file_extensions/04.mdwn:"
    assert_includes res, "file_extensions/05.mdx:"
    assert_includes res, "file_extensions/06.mkd:"
    assert_includes res, "file_extensions/07.mkdn:"
    assert_includes res, "file_extensions/08.mkdown:"
    assert_includes res, "file_extensions/09.ronn:"
    assert_includes res, "file_extensions/10.workbook:"
  end

  def test_in_flight_parsing
    res = run_rubocop("in_flight_parse.rb")

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{no offenses detected}, res
  end

  def test_non_code_offenses
    res = run_rubocop("NON_CODE_OFFENSES.md")

    assert_match %r{Inspecting 1 file}, res
    assert_match %r{no offenses detected}, res
  end
end

class RuboCop::Markdown::AutocorrectTest < Minitest::Test
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
      <<~CODE
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

    expected = <<~CODE
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
      <<~CODE
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

    expected = <<~CODE
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

  def test_autocorrect_with_compound_snippets
    prepare_test(
      <<~CODE
        Passing an array of symbols is also acceptable.

        ```ruby
        class Book
          include ActiveModel::Validations

          validates :title, presence:true, on:[:update, :ensure_title]
        end
        ```

        Assuming we have a model that's been saved in an instance variable named
        `@article`, it looks like this:

        ```html+erb
        <% if @article.errors.any? %>
          <div id="error_explanation">
            <h2><%= pluralize(@article.errors.count, "error") %> prohibited this article from being saved:</h2>

            <ul>
              <% @article.errors.each do |error| %>
                <li><%= error.full_message %></li>
              <% end %>
            </ul>
          </div>
        <% end %>
        ```

        When triggered by an explicit context, validations are run for that context,
        as well as any validations _without_ a context.

        ```ruby
        class Person < ApplicationRecord
          validates :email, uniqueness: true, on: :account_setup
              validates :age, numericality: true, on: :account_setup
            validates :name, presence: true
        end
        ```

        That's it.
      CODE
    )

    expected = <<~CODE
      Passing an array of symbols is also acceptable.

      ```ruby
      class Book
        include ActiveModel::Validations

        validates :title, presence: true, on: %i[update ensure_title]
      end
      ```

      Assuming we have a model that's been saved in an instance variable named
      `@article`, it looks like this:

      ```html+erb
      <% if @article.errors.any? %>
        <div id="error_explanation">
          <h2><%= pluralize(@article.errors.count, "error") %> prohibited this article from being saved:</h2>

          <ul>
            <% @article.errors.each do |error| %>
              <li><%= error.full_message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>
      ```

      When triggered by an explicit context, validations are run for that context,
      as well as any validations _without_ a context.

      ```ruby
      class Person < ApplicationRecord
        validates :email, uniqueness: true, on: :account_setup
        validates :age, numericality: true, on: :account_setup
        validates :name, presence: true
      end
      ```

      That's it.
    CODE

    res = run_rubocop(fixture_name, options: "--autocorrect-all")
    assert_match %r{7 offenses detected}, res
    assert_match %r{7 offenses corrected}, res

    assert_equal expected, File.read(fixture_file)
  end
end
