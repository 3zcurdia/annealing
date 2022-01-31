# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

RuboCop::RakeTask.new(:rubocop)

desc 'Execute the end-to-end integration test script'
task :end_to_end_test do
  puts
  puts 'Running full end-to-end test with bin/run'
  puts `bin/run`
  puts
end

task default: %i[test end_to_end_test rubocop]
