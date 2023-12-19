# frozen_string_literal: true

require "test_helper"

class RuboCop::Markdown::PreprocessTest < Minitest::Test
  def subject(source, warn_invalid: false)
    dummy_processed_source = RuboCop::ProcessedSource.new(source, 2.6, "test.md")
    dummy_processed_source.config = RuboCop::ConfigStore.new.for("test.md")
    obj = RuboCop::Markdown::Preprocess.new(dummy_processed_source)
    obj.define_singleton_method(:warn_invalid?) { warn_invalid }
    obj
  end

  def assert_parsed(raw_source, parsed, source_code)
    assert_equal source_code, parsed[:processed_source].raw_source, "Expected the processed_source to contain the code block"
    assert_equal raw_source.index(source_code, parsed[:offset]), parsed[:offset], "Expected the offset to start at the code block"
  end

  def test_no_code_snippets
    source = <<~SOURCE
      # Header

      Boby text
    SOURCE

    assert_equal 0, subject(source).call.size
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

    code_block = <<~SOURCE
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
    SOURCE

    parsed = subject(source).call
    assert_equal 1, parsed.size
    assert_parsed source, parsed.first, code_block
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

    code_block = <<~SOURCE
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
    SOURCE

    parsed = subject(source).call
    assert_equal 1, parsed.size
    assert_parsed source, parsed.first, code_block
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

    code_block1 = <<~SOURCE
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
    SOURCE

    code_block2 = <<~SOURCE
      require "minitest/pride"
      require "minitest/autorun"

    SOURCE

    parsed = subject(source).call
    assert_equal 2, parsed.size
    assert_parsed source, parsed[0], code_block1
    assert_parsed source, parsed[1], code_block2
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

    assert_equal 0, subject(source).call.size
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

    assert_equal 0, subject(source).call.size
  end

  def test_ambigious_non_ruby_snippet
    source = <<~SOURCE
      # Header

      ```ruby
      it "is doing heavy stuff", :rprof do
        ... # Syntax error
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

    code_block = <<~SOURCE
      TestProf::RubyProf.configure do |config|
        config.printer = :call_stack
      end
    SOURCE

    parsed = subject(source).call
    assert_equal 1, parsed.size
    assert_parsed source, parsed.first, code_block
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

    code_block1 = <<~SOURCE
      `method_call
    SOURCE

    code_block2 = <<~SOURCE
      method_call
    SOURCE

    parsed = subject(source, warn_invalid: true).call
    assert_equal 2, parsed.size
    assert_parsed source, parsed[0], code_block1
    assert_parsed source, parsed[1], code_block2
  end
end
