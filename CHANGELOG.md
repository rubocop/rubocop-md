# Change log

## master (unreleased)

- Preserve the original Markdown buffer for prose plugins and combine original-source edits with Ruby snippet corrections ([#55](https://github.com/rubocop/rubocop-md/pull/55), [@dblock][], [@Copilot][]).
- Replace standalone regex-based snippet extraction with a reusable Markdown document parser, supporting tilde fences, indented code, and code blocks inside lists and blockquotes while preserving their source prefixes during autocorrection ([#51](https://github.com/rubocop/rubocop-md/pull/51), [@dblock][], [@Copilot][]).
- Fix false indentation offenses in and after list-nested code blocks ([#28](https://github.com/rubocop/rubocop-md/issues/28), [#51](https://github.com/rubocop/rubocop-md/pull/51), [@dblock][], [@Copilot][]).

## 2.0.4 (2026-01-28)

- Enable caching when no offenses detected ([@byroot][]).

## 2.0.3 (2025-09-30)

- Fix compatibility with RuboCop upstream (`get_processed_source` signature) ([@Rylan12][]).

## 2.0.2 (2025-08-20)

- Support metadata in code blocks ([@balvig][]).

## 2.0.1 (2025-04-14)

- Remove `Layout/TrailingBlankLines` ([@rmm5t][]).

## 2.0.0 (2025-02-17)

- Migrate to new RuboCop Plugin architecture ([@koic][]).

## 1.2.4 (2024-10-16)

- Fix RuboCop warnings ([@koic][]).

## 1.2.3 (2024-09-12)

- Do no try linting `.mdx` files by default ([@larouxn][]).

## 1.2.2 (2023-12-01) ❄️

- Fix analyzing code blocks with backticks ([@palkan][]).

## 1.2.1 (2023-10-20)

- Fix incompatibility when loading the plugin from YAML and using other RuboCop options ([@prog-supdex][], [@palkan][]).

## 1.2.0 (2023-01-31)

- Fix parsing compound syntax hints in code snippets ([@palkan][]).

- Drop Ruby 2.5 support ([@palkan][]).

## 1.1.0 (2022-10-24)

- Ignore offenses in non-code source ([@palkan][]).

## 1.0.1 (2020-12-28)

- Exclude `EmptyLineBetweenDefs` for MD files ([@palkan][]).

## 1.0.0 (2020-12-24)

- Drop Ruby 2.4 support and require RuboCop 1.0 ([@palkan][]).

## 0.4.1 (2020-11-05)

- Relax required RuboCop version ([@sfeuga][]).

## 0.4.0 (2020-07-03)

- [#10](https://github.com/rubocop-hq/rubocop-md/pull/10): **Drop Ruby 2.3 support** ([@dominicsayers][]).

## 0.3.2 (2020-03-18)

- [#9](https://github.com/rubocop-hq/rubocop-md/pull/9): Add file extensions for Markdown ([@ybiquitous][]).

## 0.3.1 (2019-12-25)

- Upgrade to RuboCop 0.78 ([@palkan][]).

Change the default config to use the new cop names for (e.g., `Layout/LineLength`).

## 0.3.0 (2019-05-14)

- **Drop Ruby 2.2 support** ([@palkan][]).

[@palkan]: https://github.com/palkan
[@ybiquitous]: https://github.com/ybiquitous
[@dominicsayers]: https://github.com/dominicsayers
[@byroot]: https://github.com/byroot
[@Rylan12]: https://github.com/Rylan12
[@balvig]: https://github.com/balvig
[@rmm5t]: https://github.com/rmm5t
[@koic]: https://github.com/koic
[@larouxn]: https://github.com/larouxn
[@prog-supdex]: https://github.com/prog-supdex
[@sfeuga]: https://github.com/sfeuga
[@dblock]: https://github.com/dblock
[@Copilot]: https://github.com/Copilot
