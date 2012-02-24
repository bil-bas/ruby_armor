require 'bundler/setup'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include("*.log")
CLOBBER.include("doc/**/*")

Dir['rake/**/*.rake'].each {|f| import f }

Bundler::GemHelper.install_tasks
task :build => :gemspec
task :install => :gemspec