require 'rubygems'
require "bundler/setup"

Bundler.require 

require File.join(File.dirname(__FILE__), %w{support spec_support})

class Pgq::Consumer
    # rspec fuckup
  def self.to_ary 
  end
end

