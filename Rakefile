require 'bundler/setup'
require 'rake/clean'
require 'rake/testtask'

DISTRO_FILES = Dir[*%w<config/**/* lib/**/* media/**/* test/**/* *.md *.txt>]

CLEAN.include("*.log")
CLOBBER.include("doc/**/*")

Dir['rake/**/*.rake'].each {|f| import f }

Bundler::GemHelper.install_tasks
task :build => :gemspec
task :install => :gemspec
task :release => :gemspec