require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new("test:default") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :test do
  task :options do
    sh <<~COMMAND
      MD_LOAD_MODE=options rake test:default
    COMMAND
  end

  task :config do
    sh <<~COMMAND
      MD_LOAD_MODE=config rake test:default
    COMMAND
  end
end

RuboCop::RakeTask.new

task test: ["test:options", "test:config"]

task default: [:rubocop, :test]
