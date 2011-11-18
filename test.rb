#!/usr/bin/env ruby
$:.unshift(File.dirname(__FILE__) + '/lib') unless $:.include?(File.dirname(__FILE__) + '/lib')

require "cuke-step-bm"

CukeStepBm::Cli.execute(ARGV.dup)