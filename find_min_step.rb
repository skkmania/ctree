#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#
require 'fileutils'
require 'logger'
require "google_drive"

Lp = Struct.new :p, :id, :size, :min, :max, :pattern

class Tracer
  def initialize p, now=nil
    @now = (now ? now : 1)
    @p = p
    @r = p-1
    @in_loop = false
    @loop_ary = []
    @lp = Lp.new
    @lp.p = p
    @trace = []
    @trace_pattern = ''
  end
  attr_accessor :now, :loop_ary, :trace, :lp
  attr_reader :p,:r,:trace_pattern

  def set x
    @now = x
  end

  # x まで上がれるか?
  # 上がれるなら、上がってself
  # x,に着くまえにpathをたどれなくなるときは元の位置のままfalse
  def up_to? x, path
    dummy = Tracer.new @p, @now
    if dummy.up_tracable? path and dummy.trace.include? x
      @now = x
      @trace = dummy.trace
      return self
    else
      return false
    end
  end

  # x まで降りられるか?
  # 降りられるなら、降りてtrue
  # loopにおちてしまいxまでたどりつけないときは元の位置のままfalse
  def down_to? x
    dummy = Tracer.new @p, @now
    dummy.down_to_loop
    if dummy.trace.include? x  or  dummy.loop_ary.include? x
      @now = x
      return self
    else
      return false
    end
  end

  def down_to_loop start=nil
    if start
      @now = start
    else
      start = @now
    end
    @shadow = @now
    until @in_loop
      down
      if @now == 1
        return nil
      end
      @trace.push @now
      shadow_down
      shadow_down
      @in_loop = (@shadow == @now)
    end
    sentinel = @now
    @loop_ary.push @now
    down
    while sentinel != @now
      @loop_ary.push @now
      down
    end
    @lp.size = @loop_ary.size
    @lp.min = @loop_ary.min
    @lp.max = @loop_ary.max
  end

  def print_loop
    puts "\np: #{@p.to_s}"
    puts "loop size: #{@loop_ary.size.to_s}"
    puts "loop min: #{@loop_ary.min.to_s}"
    puts "loop max: #{@loop_ary.max.to_s}"
    puts "loop: #{@loop_ary.join(',')}"
    puts "pattern: #{@lp.pattern}"
  end

  def get_pattern
    min = @loop_ary.min
    min_pos = @loop_ary.index min
    ret = ''
    (@loop_ary[min_pos..-1] + @loop_ary[0..(min_pos)]).each_cons(2){|i,j|
      if i % @r == 0
        ret += 'R'
      else
        ret += 'L'
      end
    }
    @lp.pattern = ret 
  end
      
  def down step=nil
    div, mod = @now.divmod @r
    if mod == 0
      @now = div
      @trace_pattern += 'L'
    else
      @now = @p * @now + (@r - mod)
      @trace_pattern += 'R'
    end
  end

  def shadow_down step=nil
    div, mod = @shadow.divmod @r
    if mod == 0
      @shadow = div
    else
      @shadow = @p * @shadow + (@r - mod)
    end
  end

  def up_right
    # standard ctree で@p, @now が整数ならこれでよい
    @now = (@now) / @p
  end

  def up_rightable?
    # standard ctree で@p, @now が整数ならこれでよい
    kouho = @now / @p
    div, mod = kouho.divmod @r
    return false if mod == 0
    return (@p * kouho) + (@r - mod) == @now
  end

  def up_left
    @now = @now * @r
  end

  # pathをたどることができるか
  # pathは下向きのものが渡されるものとする
  # (他のオブジェクトの@trace_patternが渡されると想定)
  def up_tracable? path
    path.reverse.each_char{|c|
      case c
        when 'L'
          up_left
        when 'R'
          if up_rightable?
            up_right
          else
            return false
          end
      end
    }
    return true
  end

  def write_sheet
    session = GoogleDrive.login("skkmania@gmail.com", "wajiwaji2009")
  # https://docs.google.com/spreadsheet/ccc?key=0AtsWWiWPzmSbdGR4YU1sQjgtTmdkU29Pc3BqcEpUYXc#gid=0
    ws = session.spreadsheet_by_key("0AtsWWiWPzmSbdGR4YU1sQjgtTmdkU29Pc3BqcEpUYXc").worksheets[1]
    last_row = ws.num_rows + 1
    ws[last_row, 1] = @lp.p
    ws[last_row, 2] = @lp.id
    ws[last_row, 3] = @lp.size
    ws[last_row, 4] = @lp.min
    ws[last_row, 5] = @lp.max
    ws[last_row, 6] = @lp.pattern
    ws.save()
  end

end

def find_loops p
  loops = []
  numbers = (2..300000).to_a.select{|n| n if n % (p-1) != 0 }
  while numbers.size > 0
    n = numbers.shift
    t = Tracer.new p
    print "\r#{n}"
    fallen = t.down_to_loop n
    numbers -= t.trace
    next unless fallen
    if t.lp.min != 1
      t.get_pattern
      unless loops.find{|lp| t.lp.size == lp.size and t.lp.min == lp.min }
        t.lp.id = loops.size + 1
        loops.push t.lp
        t.print_loop
        t.write_sheet
      end
    end
  end
  return loops
end
if __FILE__ == $0
  (3651..15000).each{|p|
    puts "  start check p: #{p}"
    find_loops p
  }
end
