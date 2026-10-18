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

  def test_ruby_snippet_with_metadata
    source = <<~SOURCE
      # Header

      Code example:

      ```ruby test_valid_example
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
      #<--rubocop/md-->```ruby test_valid_example
      class Test < Minitest::Test
        def test_valid
          assert false
        end
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

  def test_tilde_and_long_fences_with_metadata
    ["~~~", "`````"].each do |fence|
      source = "#{fence}ruby example\nputs 'hello'\n#{fence}#{fence[0]}\n"
      expected = "#<--rubocop/md-->#{fence}ruby example\nputs 'hello'\n" \
                 "#<--rubocop/md-->#{fence}#{fence[0]}\n"

      assert_equal expected, subject.call(source)
    end
  end

  def test_indented_and_nested_code
    source = <<~MARKDOWN
      > ```ruby
      > puts 'quoted'
      > ```

      - Example:

        ~~~ruby
        puts 'listed'
        ~~~

      # Indented

          puts 'indented'
    MARKDOWN
    expected = <<~MARKDOWN
      #<--rubocop/md-->> ```ruby
      puts 'quoted'
      #<--rubocop/md-->> ```
      #<--rubocop/md-->
      #<--rubocop/md-->- Example:
      #<--rubocop/md-->
      #<--rubocop/md-->  ~~~ruby
      puts 'listed'
      #<--rubocop/md-->  ~~~
      #<--rubocop/md-->
      #<--rubocop/md--># Indented
      #<--rubocop/md-->
      puts 'indented'
    MARKDOWN

    assert_equal expected, subject.call(source)
  end

  def test_autodetect_can_disable_unlabeled_and_indented_code
    source = "```\nputs 1\n```\n\n    puts 2\n"
    processor = subject
    processor.define_singleton_method(:autodetect?) { false }

    assert_equal source.gsub(/^/, "#<--rubocop/md-->"), processor.call(source)
  end

  def test_does_not_extract_fences_inside_html_or_non_ruby_code
    source = "<div>\n```ruby\nputs 1\n```\n</div>\n\n" \
             "````markdown\n```ruby\nputs 2\n```\n````\n"

    assert_equal source.gsub(/^/, "#<--rubocop/md-->"), subject.call(source)
  end

  def test_line_inserting_corrections_restore_container_prefixes
    source = "> ```ruby\n> values = [1, 2]\n> ```\n"
    processed = RuboCop::ProcessedSource.new(source, RuboCop::TargetRuby::DEFAULT_VERSION, "test.md")
    corrector = RuboCop::Cop::Corrector.new(processed)
    corrector.replace(processed.ast.children.last.source_range, "[\n  1,\n  2\n]")

    assert_equal "> ```ruby\n> values = [\n>   1,\n>   2\n> ]\n> ```\n", corrector.rewrite
  end

  def test_line_deleting_corrections_restore_container_prefixes
    source = "- Example:\n\n  ```ruby\n  values = [\n    1,\n    2\n  ]\n  ```\n"
    processed = RuboCop::ProcessedSource.new(source, RuboCop::TargetRuby::DEFAULT_VERSION, "test.md")
    corrector = RuboCop::Cop::Corrector.new(processed)
    corrector.replace(processed.ast.children.last.source_range, "[1, 2]")

    assert_equal "- Example:\n\n  ```ruby\n  values = [1, 2]\n  ```\n", corrector.rewrite
  end

  def test_autodetect_preserves_heredoc_line_boundaries
    source = "```\nmessage = <<~TEXT\nhello\nTEXT\n```\n"
    expected = "#<--rubocop/md-->```\nmessage = <<~TEXT\nhello\nTEXT\n#<--rubocop/md-->```\n"

    assert_equal expected, subject.call(source)
  end

  def test_document_reuses_one_parse
    parser = RuboCop::Markdown::Parser
    original = parser.method(:parse)
    calls = 0
    parse = lambda do |*args|
      calls += 1
      original.call(*args)
    end
    parser.stub(:parse, parse) do
      processed = RuboCop::ProcessedSource.new("```ruby\nputs 1\n```\n", 2.7, "test.md")
      2.times { processed.markdown_document.code_blocks.to_a }
    end

    assert_equal 1, calls
  end
end
