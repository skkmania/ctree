#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# compare_tree.rb
#
require "logger"
require "./ctracer.rb"


class CompareTree < Logger::Application
  def initialize level, bound
    super('CompareTree') # Name of the application.
    @level = level
    @bound = bound
    @ij_array = (1..@bound).to_a.product (1..@bound).to_a
  end

  def run
    level = @level
    while @ij_array.size > 0 and level < 25
      search level
      level += 1
    end

  end
  
  def compare_tree level, t1, t2
    # log(Logger::INFO,'entering compare_tree')
    t1.required_level = level
    t2.required_level = level
    t1.forward
    t2.forward
#    print "\rlevel: #{t1.current_level}\tt1: #{t1.now},\tt2: #{t2.now}"
    while t1.forward == t2.forward and t1.current_level > 0
#      print "\rlevel: #{t1.current_level}\tt1: #{t1.now},\tt2: #{t2.now}"
    end
  end
  
  def search level
    # levelで相似な(i,j)の組を返す
    @log.info('entering search')
    result_array = []
    @ij_array.each{|i,j|
      t1 = CTracer.new(p:4, now:7, q:[0, 2+3*i, 1+3*j])
      t2 = CTracer.new(p:4, now:63, q:[0, 2, 1])
      compare_tree level, t1, t2
      if t1.current_level == 0
        # rootまで戻ってきた。つまり相似だった。
        result_array.push [i,j]
        puts '\nsame shape.'
        puts "\rq:[0, #{(2+3*i).to_s}, #{(1+3*j).to_s}]\tlevels 1: #{t1.levels.inspect}\tlevels 2: #{t2.levels.inspect}"
      end
    }
    @ij_array = result_array
    @log.info('search') { "search level #{level} has done." }
  end
end
  
if __FILE__ == $0

app = CompareTree.new(3,300)
app.log = 'compare_tree.log'
app.level = Logger::INFO
status = app.start
puts status

end
