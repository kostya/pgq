require 'rubygems'
require "bundler"
Bundler.setup

$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'pgq'
require 'benchmark'

require File.join(File.dirname(__FILE__), %w{.. support spec_support})

N = 5000
puts 'start benchmark'

re_queues
tm = Benchmark.realtime{ N.times{ PgqBla.bla } }
puts "insert without arguments method missing #{tm}"

re_queues
tm = Benchmark.realtime{ N.times{ PgqBla.add_event 'bla' } }
puts "insert without arguments add_event #{tm}"

x = (0..100).to_a.map{|c| {1 => c, :b => "a#{c}", 2 => c + 2}}

re_queues
tm = Benchmark.realtime{ N.times{ PgqBla.bla x } }
puts "insert arguments method missing #{tm}"

re_queues
tm = Benchmark.realtime{ N.times{ PgqBla.add_event 'bla', x } }
puts "insert arguments add_event #{tm}"
