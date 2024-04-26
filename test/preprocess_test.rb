# frozen_string_literal: true

require "test_helper"

class RuboCop::Markdown::PreprocessTest < Minitest::Test
  def subject(warn_invalid: false)
    obj = RuboCop::Markdown::Preprocess.new("test.md")
    obj.define_singleton_method(:warn_invalid?) { warn_invalid }
    obj
  end

  def test_no_code_snippets
    source = <<~SOURCE
      # Header

      Boby text
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md--># Header
      #<--rubocop/md-->
      #<--rubocop/md-->Boby text
    SOURCE

    assert_equal expected, subject.call(source)
  end

  def test_with_one_snippet
    source = <<~SOURCE
      # Header

      Code example:

      ```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      ```
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md--># Header
      #<--rubocop/md-->
      #<--rubocop/md-->Code example:
      #<--rubocop/md-->
      #<--rubocop/md-->```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      #<--rubocop/md-->```
    SOURCE

    assert_equal expected, subject.call(source)
  end

  def test_only_snippet
    source = <<~SOURCE
      ```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      ```
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md-->```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      #<--rubocop/md-->```
    SOURCE

    assert_equal expected, subject.call(source)
  end

  def test_many_snippets
    source = <<~SOURCE
      # Header

      Code example:

      ```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      ```

      More texts and lists:
      - One
      - Two

      ```ruby
      require "minitest/pride"
      require "minitest/autorun"

      ```
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md--># Header
      #<--rubocop/md-->
      #<--rubocop/md-->Code example:
      #<--rubocop/md-->
      #<--rubocop/md-->```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      #<--rubocop/md-->```
      #<--rubocop/md-->
      #<--rubocop/md-->More texts and lists:
      #<--rubocop/md-->- One
      #<--rubocop/md-->- Two
      #<--rubocop/md-->
      #<--rubocop/md-->```ruby
      require "minitest/pride"
      require "minitest/autorun"

      #<--rubocop/md-->```
    SOURCE

    assert_equal expected, subject.call(source)
  end

  def test_invalid_syntax
    source = <<~SOURCE
      # Header

      Code example:

      ```
      class Test < Minitest::Test
        def test_valid
          ...
        end
      end
      ```
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md--># Header
      #<--rubocop/md-->
      #<--rubocop/md-->Code example:
      #<--rubocop/md-->
      #<--rubocop/md-->```
      #<--rubocop/md-->class Test < Minitest::Test
      #<--rubocop/md-->  def test_valid
      #<--rubocop/md-->    ...
      #<--rubocop/md-->  end
      #<--rubocop/md-->end
      #<--rubocop/md-->```
    SOURCE

    assert_equal expected, subject.call(source)
  end

  def test_non_ruby_snippet
    source = <<~SOURCE
      # Header

      Code example:

      ```
      -module(evlms).
      -export([martians/0, martians/1]).
      ```
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md--># Header
      #<--rubocop/md-->
      #<--rubocop/md-->Code example:
      #<--rubocop/md-->
      #<--rubocop/md-->```
      #<--rubocop/md-->-module(evlms).
      #<--rubocop/md-->-export([martians/0, martians/1]).
      #<--rubocop/md-->```
    SOURCE

    assert_equal expected, subject.call(source)
  end

  def test_ambigious_non_ruby_snippet
    source = <<~SOURCE
      # Header

      ```ruby
      it "is doing heavy stuff", :rprof do
        ...
      end
      ```

      Code example:

      ```sh
      TEST_RUBY_PROF=call_stack bundle exec rake test
      ```

      Or in your code:

      ```ruby
      TestProf::RubyProf.configure do |config|
        config.printer = :call_stack
      end
      ```
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md--># Header
      #<--rubocop/md-->
      #<--rubocop/md-->```ruby
      #<--rubocop/md-->it "is doing heavy stuff", :rprof do
      #<--rubocop/md-->  ...
      #<--rubocop/md-->end
      #<--rubocop/md-->```
      #<--rubocop/md-->
      #<--rubocop/md-->Code example:
      #<--rubocop/md-->
      #<--rubocop/md-->```sh
      #<--rubocop/md-->TEST_RUBY_PROF=call_stack bundle exec rake test
      #<--rubocop/md-->```
      #<--rubocop/md-->
      #<--rubocop/md-->Or in your code:
      #<--rubocop/md-->
      #<--rubocop/md-->```ruby
      TestProf::RubyProf.configure do |config|
        config.printer = :call_stack
      end
      #<--rubocop/md-->```
    SOURCE

    assert_equal expected, subject.call(source)
  end

  def test_snippet_with_unclosed_backtick
    source = <<~SOURCE
      # Code example:

      ```ruby
      `method_call
      ```

      # Other code example

      ```ruby
      method_call
      ```
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md--># Code example:
      #<--rubocop/md-->
      #<--rubocop/md-->```ruby
      `method_call
      #<--rubocop/md-->```
      #<--rubocop/md-->
      #<--rubocop/md--># Other code example
      #<--rubocop/md-->
      #<--rubocop/md-->```ruby
      method_call
      #<--rubocop/md-->```
    SOURCE

    assert_equal expected, subject(warn_invalid: true).call(source)
  end

  def test_snippets_with_disabled_cops
    source = <<~SOURCE
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

      Cops disabled inside Ruby block

      ```ruby
      # rubocop:disable all
      def blank_method
      end
      # rubocop:enable all
      ```
    SOURCE

    expected = <<~SOURCE
      #<--rubocop/md-->All cops disabled
      #<--rubocop/md-->
      # rubocop:disable all <--rubocop/md-->
      #<--rubocop/md-->```ruby
      def blank_method
      end
      #<--rubocop/md-->```
      # rubocop:enable all <--rubocop/md-->
      #<--rubocop/md-->
      #<--rubocop/md-->All cops disabled as todos
      #<--rubocop/md-->
      # rubocop:todo all <--rubocop/md-->
      #<--rubocop/md-->```ruby
      def blank_method
      end
      #<--rubocop/md-->```
      # rubocop:enable all <--rubocop/md-->
      #<--rubocop/md-->
      #<--rubocop/md-->Cops disabled explicitly
      #<--rubocop/md-->
      # rubocop:disable Style/EmptyMethod, Style/ArrayJoin <--rubocop/md-->
      #<--rubocop/md-->```ruby
      def blank_method
      end

      %w[foo bar baz] * ","
      #<--rubocop/md-->```
      # rubocop:enable Style/EmptyMethod, Style/ArrayJoin <--rubocop/md-->
      #<--rubocop/md-->
      #<--rubocop/md-->Cops disabled inside Ruby block
      #<--rubocop/md-->
      #<--rubocop/md-->```ruby
      # rubocop:disable all
      def blank_method
      end
      # rubocop:enable all
      #<--rubocop/md-->```
    SOURCE

    assert_equal expected, subject.call(source)
  end
end
