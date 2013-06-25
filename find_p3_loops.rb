#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#
#  find_p3_loops.rb :
#    p = 3のとき、qを動かし、それぞれのqによりループを探し、結果を報告する
#    報告先は GoogleDrive spreadsheet と 標準出力
#    GoogleDriveのsheetは、.googledrive.conf により指定する
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
      if @shadow == 1
        return nil
      end
      @loop_ary.shift
      @now = @loop_ary[0]
      @in_loop = (@shadow == @now)
    end
    @loop_ary = @loop_ary[0..(@loop_ary[1..-1].index @loop_ary[0])]
    @lp.size = @loop_ary.size
    @lp.min = @loop_ary.min
    @lp.max = @loop_ary.max
  end

  def print_loop
    puts "\nq: #{@q.to_s}"
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
        ret += '0'
      else
        ret += '1'
      end
    }
    @lp.pattern = ret 
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

  def set_google address, pwd, key
    @address = address
    @pwd = pwd
    @key = key
  end

  def write_sheet
    session = GoogleDrive.login(@address, @pwd)
    ws = session.spreadsheet_by_key(@key).worksheets[1]
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

def find_loops p, q
=begin
  lines = open('./.googledrive.conf').readlines.map{|l| l.chomp }
  address = lines[0].split(':')[1]
  pwd = lines[1].split(':')[1]
  key = lines[2].split(':')[1]
=end
  loops = []
  start_x = 1
  end_x = start_x + [q,3000].max
  (start_x..end_x).each{|n|
    t = Tracer.new p, q, n
    # t.set_google address, pwd, key
    STDERR.print "\r#{n}"
    fallen = t.down_to_loop n
    next unless fallen
    if t.lp.min != 1
      t.get_pattern
      unless loops.find{|lp| t.lp.size == lp.size and t.lp.min == lp.min }
        # 新発見ならばidを増やし報告する
        t.lp.id = loops.size + 1
        loops.push t.lp
        t.print_loop
       # t.write_sheet
      end
    end
  }
  return loops
end
if __FILE__ == $0
  p = 3
  (3001..5000).each{|i|
    q = 2*i + 1
    STDERR.puts "  start check q: #{q}"
    find_loops p, q
  }
end
