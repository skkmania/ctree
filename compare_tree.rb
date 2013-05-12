#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# compare_tree.rb
#
require "./ctracer.rb"


def compare_tree level, t1, t2
  t1.required_level = level
  t2.required_level = level
  t1.forward
  t2.forward
  print "\rlevel: #{t1.current_level}\tt1: #{t1.now},\tt2: #{t2.now}"
  while t1.forward == t2.forward and t1.current_level > 0
    print "\rlevel: #{t1.current_level}\tt1: #{t1.now},\tt2: #{t2.now}"
  end
end

def search level, ij_array
  result_array = []
  ij_array.each{|i,j|
    t1 = CTracer.new(p:4, now:7, q:[0, 2+3*i, 1+3*j])
    t2 = CTracer.new(p:4, now:7, q:[0, 2, 1])
    compare_tree level, t1, t2
    if t1.current_level == 0
      result_array.push [i,j]
      puts '\nsame shape.'
      puts "q:[0, #{(2+3*i).to_s}, #{(1+3*j).to_s}]"
      puts "levels 1: #{t1.levels.inspect}"
      puts "levels 2: #{t2.levels.inspect}"
    end
  }
  return result_array
end
  
if __FILE__ == $0

level = 3
bound = 1000
ij_array = (1..bound).to_a.product (1..bound).to_a
while ij_array.size > 0 and level < 10
  ij_array = search level, ij_array
  level += 1
end

end
