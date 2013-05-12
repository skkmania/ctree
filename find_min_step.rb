#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# find_min_step.rb
#
require "./ctracer.rb"


def find_min_step tgt
  seed = tgt / 10

  results = []
  (seed..seed+100).to_a.each{|p|
    print "\r p: #{p}"
    t = CTracer.new(p: p, now: tgt)
    t.down_to_loop
    results.push t
    print "\r p: #{p},  step: #{t.trace.size}"
  }
  return results
end

if __FILE__ == $0
  res = find_min_step ARGV[0].to_i
  res = res.sort{|x,y| x.trace.size <=> y.trace.size }
  puts
  (0..20).to_a.each{|i|
    puts "p: #{res[i].p}, step: #{res[i].trace.size}"
  }
end
