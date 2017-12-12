[![Gem Version](https://badge.fury.io/rb/rubocop-md.svg)](http://badge.fury.io/rb/rubocop-md)
[![Travis Status](https://travis-ci.org/palkan/rubocop-md.svg?branch=master)](https://travis-ci.org/palkan/rubocop-md)

# Rubocop Markdown

Run Rubocop against your Markdown files to make sure that code examples follow style guidelines and have valid syntax.

## Features

- Analyzes code blocks within Markdown files
- Shows correct line numbers in output
- Preserves specified language (i.e., do not try to analyze "\`\`\`sh")
- **Supports autocorrect 📝**

This project was developed to keep [test-prof](https://github.com/palkan/test-prof) guides consistent with Ruby style guide.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-md'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rubocop-md

## Usage

### Command line

Just require `rubocop-md` in your command:

```sh
rubocop -r "rubocop-md" ./lib
```

Autocorrect works too:

```sh
rubocop -r "rubocop-md" -a ./lib
```

### Configuration file

First, add `rubocop-md` to your `.rubocop.yml`:

```yml
require:
 - "rubocop-md"
```

Additional options:

```yml
# .rubocop.yml
Markdown:
  # Whether to run RuboCop against non-valid snippets
  WarnInvalid: true
```

## How it works?

- Preprocess Markdown source into Ruby source preserving line numbers
- Let RuboCop do its job
- Restore Markdown from preprocessed Ruby if it has been autocorrected

## Limitations

- RuboCop cache is disabled for Markdown files (because cache knows nothing about preprocessing)
- Uses naive Regexp-based approach to extract code blocks from Markdown, support only backticks-style code blocks
- No language detection included; if you do not specify language for your code blocks, you'd better turn `WarnInvalid` off (see above)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/rubocop-md.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
