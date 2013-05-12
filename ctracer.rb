#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# ctracer.rb
require 'fileutils'
require 'logger'
require "google_drive"

Lp = Struct.new :p, :id, :size, :min, :max, :pattern

class CTracer
  def initialize(p: nil, now: nil, q: nil)
    @now = (now ? now : 1)
    @p = (p ? p : 3)
    @r = p-1
    @q = (q ? q : (@r..1).to_a)
    @in_loop = false
    @loop_ary = []
    @lp = Lp.new
    @lp.p = p
    @trace = []
    @trace_pattern = ''
    @current_level = 0
    @required_level = 0
    @prev_move = 'L'
    @levels = Hash.new{|h,k|h[k]=[]}
  end
  attr_accessor :now, :loop_ary, :trace, :lp, :required_level
  attr_reader :p,:r,:trace_pattern, :current_level, :levels

  def set x
    @now = x
  end

  # x まで上がれるか?
  # 上がれるなら、上がってself
  # x,に着くまえにpathをたどれなくなるときは元の位置のままfalse
  def up_to? x, path
    dummy = CTracer.new @p, @now
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
    dummy = CTracer.new @p, @now
    dummy.down_to_loop
    if dummy.trace.include? x  or  dummy.loop_ary.include? x
      @now = x
      return self
    else
      return false
    end
  end

  # 右回りに木を走査する
  # その一歩をforwardと呼ぶ
  # ,返り値 文字 直前の動作を表現する
  #    L : treeの左上方に @now = (@p - 1) * @now
  #    R : treeの右上方に @now = (@now - q) / @p
  #    l : Lの反対 @now = @now / (@p - 1)
  #    r : Rの反対 @now = @p * @now + q
  def forward
    if @current_level < @required_level
      case @prev_move
      when 'L'
        up_left
        @prev_move = 'L'
        @current_level += 1
      when 'l'
        if up_rightable?
          up_right
          @prev_move = 'R'
          @current_level += 1
        else
          if down_leftable?
            down_left
            @prev_move = 'l'
            @current_level -= 1
          else
            down_right
            @prev_move = 'r'
            @current_level -= 1
          end
        end
      when 'r'
        down_left
        @prev_move = 'l'
        @current_level -= 1
      when 'R'
        up_left
        @prev_move = 'L'
        @current_level += 1
      else
        raise '[BUG]impossible prev_move in forward'
      end
    else
      if @current_level == @required_level
        case @prev_move
        when 'L'
          down_left
          @prev_move = 'l'
          @current_level -= 1
        when 'R'
          down_right
          @prev_move = 'r'
          @current_level -= 1
        else
          raise '[BUG]went over level?'
        end
      else
        raise '[BUG]current level exceeds requirement.'
      end
    end
    @levels[@current_level].push @now if (@prev_move == 'L' or @prev_move == 'R')
    return @prev_move
  end

  # std loopは除く
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
      @trace.push @now
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
# print "\r now: #@now"
    div, mod = @now.divmod @r
    if mod == 0
      @now = div
      @trace_pattern += 'L'
    else
      @now = @p * @now + @q[mod]
      @trace_pattern += 'R'
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
    if @up_right
      @now = @up_right
      @up_right = nil
      return
    else
      if up_rightable?
        @now = @up_right
        @up_right = nil
        return
      else
        raise '[BUG]up_right is failed because impossible call'
      end
    end
  end

  def up_rightable?
    kouho_array = @q.map{|q| @now - q }
    (1..(@r-1)).each{|i|
      next if kouho_array[i] <= 0
      div, mod = kouho_array[i].divmod @p
      next if div == 0
      if mod == 0 and (div * @p + @q[div % @r]) == @now
        @up_right = div
        return true
      end
    }
    @up_right = nil
    return false
  end

  def up_left
    @now = @now * @r
  end

  def down_right
    @now = @p * @now + @q[@now % @r]
  end

  def down_left
    @now = @now / @r
  end

  def down_leftable?
    @now % @r == 0
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
  numbers = (2..300000).to_a.select{|n| n if n % (p-1) != 0 }
  while numbers.size > 0
    n = numbers.shift
    t = CTracer.new p
    t.set_google address, pwd, key
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
