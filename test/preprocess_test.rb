require "test_helper"

using SquigglyHeredoc

class RuboCop::Markdown::PreprocessTest < Minitest::Test
  def subject
    RuboCop::Markdown::Preprocess.new("test.md").tap do |obj|
      # Avoid syntax warnings
      def obj.warn_invalid?
        false
      end
    end
  end

  def test_no_code_snippets
    source = <<-SOURCE.squiggly
      # Header

      Boby text
    SOURCE

    expected = <<-SOURCE.squiggly
      #<--rubocop/md--># Header
      #<--rubocop/md-->
      #<--rubocop/md-->Boby text
    SOURCE

    assert_equal expected, subject.call(source)
  end

  def test_with_one_snippet
    source = <<-SOURCE.squiggly
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

    expected = <<-SOURCE.squiggly
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
    source = <<-SOURCE.squiggly
      ```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      ```
    SOURCE

    expected = <<-SOURCE.squiggly
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
    source = <<-SOURCE.squiggly
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

    expected = <<-SOURCE.squiggly
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
    source = <<-SOURCE.squiggly
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

    expected = <<-SOURCE.squiggly
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
    source = <<-SOURCE.squiggly
      # Header

      Code example:

      ```
      -module(evlms).
      -export([martians/0, martians/1]).
      ```
    SOURCE

    expected = <<-SOURCE.squiggly
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
    source = <<-SOURCE.squiggly
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

    expected = <<-SOURCE.squiggly
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
end
