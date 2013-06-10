#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#
#  find_loops.rb :
#    p を動かし、それぞれdefaultのqによりループを探し、結果を報告する
#    報告先は GoogleDrive spreadsheet と 標準出力
#    GoogleDriveのsheetは、.googledrive.conf により指定する
#
require 'fileutils'
require 'logger'
require "google_drive"

Lp = Struct.new :p, :id, :size, :min, :max, :pattern

class Tracer
  #   p と 開始点 を与えるとdefault のqを使いループに到着するまで木を下降する 
  def initialize p, now=nil
    @now = (now ? now : 1)
    @p = p
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
    else
      @now = @p * @now + (@r - mod)
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
    mod = kouho % @r
    return false if mod == 0
    return (@p * kouho) + (@r - mod) == @now
  end

  def up_left
    @now = @now * @r
  end

  def retracable? path
    # pathを逆にたどることができるか
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

def find_loops p
  lines = open('./.googledrive.conf').readlines.map{|l| l.chomp }
  address = lines[0].split(':')[1]
  pwd = lines[1].split(':')[1]
  key = lines[2].split(':')[1]
  loops = []
  seed = 10**20
  (seed..seed+3000000).each{|n|
    t = Tracer.new p, n
    t.set_google address, pwd, key
    print "\r#{n}"
    fallen = t.down_to_loop n
    next unless fallen
    if t.lp.min != 1
      t.get_pattern
      unless loops.find{|lp| t.lp.size == lp.size and t.lp.min == lp.min }
        # 新発見ならばidを増やし報告する
        t.lp.id = loops.size + 1
        loops.push t.lp
        t.print_loop
        t.write_sheet
        system "echo loop found at p: #{p}.\n loop: #{t.loop_ary.join(',')} see GoogleDrive. | mail -s 'find_loops report from #{`hostname`}' skphack@gmail.com"
      end
    end
  }
  return loops
end
if __FILE__ == $0
  # 2013.6.11 現在、ひとつしかループが発見されていないpについて捜索する
  [6,8,9,14,15,19,20,22,23,27,29,31,33,34,35,36,37,38,39,40].each{|p|
    puts "  start check p: #{p}"
    find_loops p
  }
  system "echo find_loops ended. | mail -s 'find_loops report from #{`hostname`}' skphack@gmail.com"
end
