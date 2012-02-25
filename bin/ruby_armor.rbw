#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path("../../lib/ruby_armor", __FILE__)

require "ruby_armor"

RubyArmor::Window.new.show unless defined? Ocra