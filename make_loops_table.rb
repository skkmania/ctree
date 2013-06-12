#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#
#  make_loops_table.rb :
#    p, q を動かし、ループを探し、結果を報告する
#    報告先は GoogleDrive spreadsheet と 標準出力 と logfile
#    GoogleDriveのsheetは、.googledrive.conf により指定する
#
require 'fileutils'
require 'logger'
require "google_drive"

Lp = Struct.new :p, :id, :size, :min, :max, :pattern

class Tracer
  #   p , q , 開始点 を与えるとループに到着するまで木を下降する 
  def initialize p, q, now=nil
    @now = (now ? now : 1)
    @p = p
    @r = p-1
    @q = q
    @in_loop = false
    @loop_ary = [@now]
    @lp = Lp.new
    @lp.p = p
  end
  attr_accessor :loop_ary, :lp, :now

  def down_to_loop_from start=nil
    if start
      @now = start
    end
    @in_loop = false
    @loop_ary = [@now]
    @shadow = @now
    until @in_loop
      shadow_down
      @loop_ary.push @shadow
      shadow_down
      @loop_ary.push @shadow
      # return nil if @shadow == 1
      @loop_ary.shift
      @now = @loop_ary[0]
      @in_loop = (@shadow == @now)
    end
    idx = @loop_ary[1..-1].index @loop_ary[0]
    @loop_ary = @loop_ary[0..idx]
    @lp.size = @loop_ary.size
    @lp.min = @loop_ary.min
    @lp.max = @loop_ary.max
    return true
  end

  def print_loop
    puts "\n  p: #{@p.to_s},  q: #{@q.to_s}"
    puts "loop id: #{@lp.id}" 
    puts "loop size: #{@loop_ary.size.to_s}"
    puts "loop min: #{@loop_ary.min.to_s},  max: #{@loop_ary.max.to_s}"
    puts "loop: #{@loop_ary.join(',')}"
    puts "pattern: #{@lp.pattern}"
    return [@p, @q.to_s, @lp.id, @loop_ary.size, @loop_ary.min, @loop_ary.max,@loop_ary.join(','),@lp.pattern]
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
      @now = @p * @now + @q[mod]
    end
  end

  def shadow_down step=nil
    div, mod = @shadow.divmod @r
    if mod == 0
      @shadow = div
    else
      @shadow = @p * @shadow + @q[mod]
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
    return (@p * kouho) + @q[mod] == @now
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

end

class GoogleWriter
  def initialize
    lines = open('./.googledrive.conf').readlines.map{|l| l.chomp }
    @address = lines[0].split(':')[1]
    @pwd = lines[1].split(':')[1]
    @key = lines[4].split(':')[1]
    @session = GoogleDrive.login(@address, @pwd)
  end

  def write_list lists_table
    ws = @session.spreadsheet_by_key(@key).worksheets[1]
      puts lists_table.to_s
      puts "lists update"
      ws.update_cells(2,2,lists_table)
      ws.save()
      puts "done"
  end

  def write_table table
    ws = @session.spreadsheet_by_key(@key).worksheets[0]
      puts table.to_s
      puts "update"
      ws.update_cells(2,2,table)
      ws.save()
      puts "done"
  end
end

def find_loops p, q
  loops = []
  lists = []
  seed = 1
  (seed..seed+3000).each{|n|
    #print "\r#{n}"
    t = Tracer.new p, q, n
    fallen = t.down_to_loop_from n
    next unless fallen
      t.get_pattern
      unless loops.find{|lp| t.lp.size == lp.size and t.lp.min == lp.min }
        # 新発見ならばidを増やし報告する
        t.lp.id = loops.size + 1
        loops.push t.lp
        lists.push t.print_loop
      #  system "echo loop found at p: #{p}.\n loop: #{t.loop_ary.join(',')} see GoogleDrive. | mail -s 'find_loops report from #{`hostname`}' skphack@gmail.com"
      end
  }
  return [loops,lists]
end
if __FILE__ == $0
  ofile = open('data/p4_num_of_loops_table.csv','w')
  o_list_file = open('data/p4_loops_list.csv','w')
  o_table = []
  o_lists_table = []
  p = 4
  bound = 30
  (0..bound).each{|i|
    o_table[i] = []
    (0..bound).each{|j|
      q = [0, 2 + i*(p-1), 1 + j*(p-1)] 
      puts "\n  start check q: #{q.to_s}"
      loops,lists = find_loops p, q
      ofile.puts "(#{i}:#{j}),#{loops.size}"
      lists.each{|list| o_list_file.puts list.join(':') } 
      o_table[i][j] = loops.size
      o_lists_table += lists
    }
  }
  o_list_file.close
  ofile.close
=begin
  gw = GoogleWriter.new 
  gw.write_table o_table
  gw.write_list o_lists_table
=end
  # system "echo find_loops ended. | mail -s 'find_loops report from #{`hostname`}' skphack@gmail.com"
end
