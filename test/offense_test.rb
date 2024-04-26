# frozen_string_literal: true

require "test_helper"

class RuboCop::Markdown::OffenseTest < RuboCop::Markdown::Test
  def overwrite_config
    @old_store = RuboCop::Markdown.config_store
    store = RuboCop::ConfigStore.new
    store.instance_variable_set(:@options_config, config)
    RuboCop::Markdown.config_store = store
  end

  def teardown
    RuboCop::Markdown.config_store = @old_store if @old_store
  end

  def test_single_snippet
    assert_offense(<<~MARKDOWN)
      # Before All

      Rails has a great feature – `transactional_tests`, i.e. running each example within a transaction which is roll-backed in the end.

      Of course, we can do something like this:

      ```ruby
      describe BeatleWeightedSearchQuery do
        before(:each) do
          @paul = create(:beatle, name: "Paul")
          @ringo = create(:beatle, name: "Ringo")
          @george = create(:beatle, name: "George")
          @john = create(:beatle, name: 'John')
                                        ^^^^^^ Style/StringLiterals: Prefer double-quoted strings unless you need single quotes to avoid extra backslashes for escaping.
        end

        # and about 15 examples here
      end
      ```
    MARKDOWN

    assert_correction(<<~MARKDOWN)
      # Before All

      Rails has a great feature – `transactional_tests`, i.e. running each example within a transaction which is roll-backed in the end.

      Of course, we can do something like this:

      ```ruby
      describe BeatleWeightedSearchQuery do
        before(:each) do
          @paul = create(:beatle, name: "Paul")
          @ringo = create(:beatle, name: "Ringo")
          @george = create(:beatle, name: "George")
          @john = create(:beatle, name: "John")
        end

        # and about 15 examples here
      end
      ```
    MARKDOWN
  end

  def test_multiple_snippets
    assert_offense(<<~MARKDOWN)
      # Custom RuboCop Cops

      TestProf comes with the [RuboCop](https://github.com/bbatsov/rubocop) cops that help you write more performant tests.

      To enable them:

      - Require `test_prof/rubocop` in your RuboCop configuration:

      ```yml
      # .rubocop.yml
      require:
      - 'test_prof/rubocop'
      ```

      - Enable cops:

      ```yml
      RSpec/AggregateFailures:
        Enabled: true
        Include:
          - 'spec/**/*.rb'
      ```

      ## RSpec/AggregateFailures

      This cop encourages you to use one of the greatest features of the recent RSpec – aggregating failures within an example.

      Instead of writing one example per assertion, you can group _independent_ assertions together, thus running all setup hooks only once. That can dramatically increase your performance (by reducing the total number of examples).

      Consider an example:

      ```ruby
      # bad
      it { is_expected.to be_success }
      it { is_expected.to have_header("X-TOTAL-PAGES",10) }
                                                     ^ Layout/SpaceAfterComma: Space missing after comma.
      it {is_expected.to have_header("X-NEXT-PAGE", 2)}
                                                      ^ Layout/SpaceInsideBlockBraces: Space missing inside }.
          ^ Layout/SpaceInsideBlockBraces: Space missing inside {.
      ```

      That's the better way:

      ```
      # good
      it "returns the second page",:aggregate_failures do
                                  ^ Layout/SpaceAfterComma: Space missing after comma.
        is_expected.to be_success
        is_expected.to have_header("X-TOTAL-PAGES", 10)
        is_expected.to have_header("X-NEXT-PAGE", 2)
      end
      ```

      This cop supports auto-correct feature, so you can automatically refactor you legacy tests!

      **NOTE**: auto-correction may break your tests (especially the ones using block-matchers, such as `change`).
    MARKDOWN

    assert_correction(<<~MARKDOWN)
      # Custom RuboCop Cops

      TestProf comes with the [RuboCop](https://github.com/bbatsov/rubocop) cops that help you write more performant tests.

      To enable them:

      - Require `test_prof/rubocop` in your RuboCop configuration:

      ```yml
      # .rubocop.yml
      require:
      - 'test_prof/rubocop'
      ```

      - Enable cops:

      ```yml
      RSpec/AggregateFailures:
        Enabled: true
        Include:
          - 'spec/**/*.rb'
      ```

      ## RSpec/AggregateFailures

      This cop encourages you to use one of the greatest features of the recent RSpec – aggregating failures within an example.

      Instead of writing one example per assertion, you can group _independent_ assertions together, thus running all setup hooks only once. That can dramatically increase your performance (by reducing the total number of examples).

      Consider an example:

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

      This cop supports auto-correct feature, so you can automatically refactor you legacy tests!

      **NOTE**: auto-correction may break your tests (especially the ones using block-matchers, such as `change`).
    MARKDOWN
  end

  def test_multiple_invalid_snippets
    skip("JRuby doesn't produce the second Lint/Syntax error") if RUBY_ENGINE == "jruby"
    assert_offense(<<~MARKDOWN)
      TestProf provides a built-in shared context for RSpec to profile examples individually:

      ```ruby
      it "is doing heavy stuff", :rprof do
        { unclosed: hash
      end
      ^^^ Lint/Syntax: unexpected token kEND
      ```

      ### Configuration

      The most useful configuration option is `printer` – it allows you to specify a RubyProf [printer](https://github.com/ruby-prof/ruby-prof#printers).

      You can specify a printer through environment variable `TEST_RUBY_PROF`:

      ```sh
      TEST_RUBY_PROF=call_stack bundle exec rake test
      ```

      Or in your code:

      ```ruby
      TestProf::RubyProf.configure do |config|
        config.printer = :call_stack
      end
      ```
      ^{} Lint/Syntax: unexpected token $end
    MARKDOWN
  end

  def test_multiple_invalid_snippets_file_no_warn
    @config = { "Markdown" => { "WarnInvalid" => false } }
    overwrite_config

    assert_no_offenses(<<~MARKDOWN)
      TestProf provides a built-in shared context for RSpec to profile examples individually:

      ```ruby
      it "is doing heavy stuff", :rprof do
        ...
      end
      ```

      ### Configuration

      The most useful configuration option is `printer` – it allows you to specify a RubyProf [printer](https://github.com/ruby-prof/ruby-prof#printers).

      You can specify a printer through environment variable `TEST_RUBY_PROF`:

      ```sh
      TEST_RUBY_PROF=call_stack bundle exec rake test
      ```

      Or in your code:

      ```ruby
      TestProf::RubyProf.configure do |config|
        config.printer = :call_stack
      end
      ```
    MARKDOWN
  end

  def test_in_flight_parsing
    assert_no_offenses(<<~RUBY, "test.rb")
      # frozen_string_literal: true

      { complex_symbol: 0 }
    RUBY
  end

  # rubocop:disable Layout/TrailingWhitespace
  def test_non_code_offenses
    assert_no_offenses(<<~MARKDOWN)
      # No Code

      Just a line with a trailining whitespace 

    MARKDOWN
  end
  # rubocop:enable Layout/TrailingWhitespace

  def test_backticks_in_code
    assert_offense(<<~MARKDOWN, marker: "##{RuboCop::Markdown::Preprocess::MARKER}")
      ```ruby
      `method_call
      ```
      _{marker} ^ Lint/Syntax: unexpected token tXSTRING_BEG


      ```ruby
      further_code("", '')
      ```
    MARKDOWN
  end

  def test_compound_snippets
    assert_offense(<<~MARKDOWN)
      Passing an array of symbols is also acceptable.

      ```ruby
      class Book
        include ActiveModel::Validations

        validates :title, presence:true, on:[:update, :ensure_title]
                                            ^^^^^^^^^^^^^^^^^^^^^^^^ Style/SymbolArray: Use `%i` or `%I` for an array of symbols.
                                           ^ Layout/SpaceAfterColon: Space missing after colon.
                                  ^ Layout/SpaceAfterColon: Space missing after colon.
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
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Layout/IndentationConsistency: Inconsistent indentation detected.
      ^^^^^^ Layout/IndentationWidth: Use 2 (not 6) spaces for indentation.
          validates :name, presence: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Layout/IndentationConsistency: Inconsistent indentation detected.
      ^^^^ Layout/IndentationWidth: Use 2 (not 4) spaces for indentation.
      end
      ```

      That's it.
    MARKDOWN

    assert_correction(<<~MARKDOWN)
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
    MARKDOWN
  end

  def test_snippets_with_disabled_cops
    assert_offense(<<~MARKDOWN)
      All cops disabled

      <span style="display:none;"># rubocop:disable all</span>
      ```ruby
      def blank_method
      end
      ```
      <span style="display:none;"># rubocop:enable all</span>

      All cops disabled as todos

      <span style="display:none;"># rubocop:todo all</span>
      ```ruby
      def blank_method
      end
      ```
      <span style="display:none;"># rubocop:enable all</span>

      Cops disabled explicitly

      <span style="display:none;"># rubocop:disable Style/EmptyMethod, Style/ArrayJoin</span>
      ```ruby
      def blank_method
      end

      %w[foo bar baz] * ","
      ```
      <span style="display:none;"># rubocop:enable Style/EmptyMethod, Style/ArrayJoin</span>

      Cops disabled in Ruby block

      ```ruby
      # rubocop:disable all
      def blank_method
      end
      # rubocop:enable all
      ```

      Actually failing cop (correctable)

      ```ruby
      %w[foo bar baz] * ","
                      ^ Style/ArrayJoin: Favor `Array#join` over `Array#*`.
      ```
    MARKDOWN

    assert_correction(<<~MARKDOWN)
      All cops disabled

      <span style="display:none;"># rubocop:disable all</span>
      ```ruby
      def blank_method
      end
      ```
      <span style="display:none;"># rubocop:enable all</span>

      All cops disabled as todos

      <span style="display:none;"># rubocop:todo all</span>
      ```ruby
      def blank_method
      end
      ```
      <span style="display:none;"># rubocop:enable all</span>

      Cops disabled explicitly

      <span style="display:none;"># rubocop:disable Style/EmptyMethod, Style/ArrayJoin</span>
      ```ruby
      def blank_method
      end

      %w[foo bar baz] * ","
      ```
      <span style="display:none;"># rubocop:enable Style/EmptyMethod, Style/ArrayJoin</span>

      Cops disabled in Ruby block

      ```ruby
      # rubocop:disable all
      def blank_method
      end
      # rubocop:enable all
      ```

      Actually failing cop (correctable)

      ```ruby
      %w[foo bar baz].join(",")
      ```
    MARKDOWN
  end
end
