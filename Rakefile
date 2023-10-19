require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(:rubocop_md_tests) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

task :test do
  ENV["MD_LOAD_MODE"] = "inline"
  $stdout.puts "⚙️ Runs rubocop with '-r rubocop_md' options"
  Rake::Task[:rubocop_md_tests].invoke

  ENV["MD_LOAD_MODE"] = "config"
  $stdout.puts "⚙️ Runs rubocop with 'required rubocop_md' section in .rubocop.yml"
  Rake::Task[:rubocop_md_tests].reenable
  Rake::Task[:rubocop_md_tests].invoke
end

task default: [:rubocop, :test]
