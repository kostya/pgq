require 'rubygems'
require 'bundler/setup'
require 'bundler'
Bundler::GemHelper.install_tasks

load 'lib/tasks/pgq.rake'

require 'rspec/core/rake_task'

task :default => :spec
RSpec::Core::RakeTask.new(:spec)

desc "set_env" 
task :set_env do
  ENV["PGQFILE"] = File.join(File.dirname(__FILE__), %w{ spec app config pgq_test.ini })
  ENV["RAILS_ROOT"] = File.join(File.dirname(__FILE__), %w{ spec app })
  ENV["RAILS_ENV"] = "test"        
end

desc "prepare test"
task :prepare_test => :set_env do
  Rake::Task["pgq:generate_config"].invoke
  Rake::Task["pgq:install"].invoke
end

task :spec => :prepare_test