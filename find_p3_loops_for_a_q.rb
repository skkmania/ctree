#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#
#  find_p3_loops_for_a_q.rb :
#  Usage: find_p3_loops_for_a_q.rb q
#    指定されたqのループを探し、結果を報告する
#    p = 3 と決め打ち。
#    報告先は 標準出力
#
require 'fileutils'
require 'logger'
require "google_drive"

Lp = Struct.new :p, :id, :size, :min, :max, :pattern

class Tracer
  #   p と 開始点 を与えるとdefault のqを使いループに到着するまで木を下降する 
  def initialize p, q, now=nil
    @now = (now ? now : 1)
    @p = p
    @q = q
    @r = p-1
    @in_loop = false
    @loop_ary = [@now]
    @lp = Lp.new
    @lp.p = p
  end
  attr_accessor :loop_ary, :lp

  def set x
    @now = x
  end

  def down_to_loop start=nil
    if start
      @now = start
    end
    @loop_ary = [@now]
    @shadow = @now
    until @in_loop
      shadow_down
      @loop_ary.push @shadow
      shadow_down
      @loop_ary.push @shadow
      if @shadow < start
        return nil
      end
      @loop_ary.shift
      @now = @loop_ary[0]
      @in_loop = (@shadow == @now)
    end
    @loop_ary = @loop_ary[0..(@loop_ary[1..-1].index @loop_ary[0])]
    @loop_ary.rotate!(@loop_ary.index(@loop_ary.min))
    @lp.size = @loop_ary.size
    @lp.min = @loop_ary.min
    @lp.max = @loop_ary.max
    get_pattern
  end

  def print_loop
    puts "\nq: #{@q.to_s}"
    puts "id: #{@lp.id}"
    puts "size: #{@loop_ary.size}"
    puts "#0: #{@lp.pattern.count('0')}"
    puts "#1: #{@lp.pattern.count('1')}"
    puts "min: #{@loop_ary.min}"
    puts "max: #{@loop_ary.max}"
    puts "loop: #{@loop_ary.join(',')}"
    puts "pattern: #{@lp.pattern}"
  end

  def get_pattern
    ret = ''
    @loop_ary.each_cons(2){|i,j|
      if i % @r == 0
        ret += '0'
      else
        ret += '1'
      end
    }
    @lp.pattern = ret + '0'
  end
      
  def down step=nil
    div, mod = @now.divmod @r
    if mod == 0
      @now = div
    else
      @now = @p * @now + @q
    end
  end

  def shadow_down step=nil
    div, mod = @shadow.divmod @r
    if mod == 0
      @shadow = div
    else
      @shadow = @p * @shadow + @q
    end
  end

  def up_right
    @now = (@now - @q) / @p
  end

  def up_rightable?
    kouho = (@now - @q) / @p
    mod = kouho % @r
    return false if mod == 0
    return (@p * kouho) + @q == @now
  end

  def up_left
    @now = @now * @r
  end
end

def find_loops p, q
  loops = []
  start_x = 1
  end_x = start_x + [q,10**8].max
  (start_x..end_x).each{|n|
    t = Tracer.new p, q, n
    STDERR.print "\r#{n}"
    fallen = t.down_to_loop n
    next unless fallen
    unless loops.find{|lp| t.lp.size == lp.size and t.lp.min == lp.min }
      # 新発見ならばidを増やし報告する
      t.lp.id = loops.size + 1
      loops.push t.lp
      t.print_loop
    end
  }
  return loops
end
if __FILE__ == $0
  q = ARGV[0].to_i
  if q.even?
    puts "q must be odd.but #{q} was given."
    exit
  end
  p = 3
  ary = find_loops p, q
  puts ary.inspect
end
