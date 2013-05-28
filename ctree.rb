#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# ctree.rb
require 'fileutils'
require 'logger'
require 'gexf'
require "google_drive"
require './ctracer.rb'

Lp = Struct.new :p, :id, :size, :min, :max, :pattern

class Node
  attr_accessor :value, :child, :parent, :prev_move
  def initialize value:nil, child:nil, parent: nil, prev_move: nil
    @value = (value ? value : 1)
    @child = (child ? child : nil)
    @parent = (parent ? parent : nil)
    @prev_move = (prev_move ? prev_move : nil)
  end
  def make_child tracer
    level = Level.new
    tracer.ups.each{|k, v|
      n = Node.new(value:v, parent:self, prev_move:k)
      level.push n
    }
    level.parent = self
    @child = level
  end
end

class Level
  include Enumerable

  attr_accessor :nodes, :child, :parent
  def initialize nodes:nil, child:nil, parent: nil
    @nodes = (nodes ? nodes : [])
    @child = child
    @parent = (parent ? parent : Node.new)
  end

  def push x
    @nodes.push x
  end

  def each
    @nodes.each{|node|
      yield node
    }
  end
end

class Levels
  include Enumerable

  attr_accessor :levels, :child, :parent
  def initialize levels:nil, child:nil, parent: nil
    @levels = (levels ? levels : [])
    @child = child
    @parent = parent
  end

  def push x
    @levels.push x
  end

  def each
    @levels.each{|level|
      yield level
    }
  end

  def each_node
    @levels.each{|lvl| lvl.each{|node| yield node } }
  end
end

class CTree
  include Enumerable
  attr_accessor :tree_levels
  def initialize(p: nil, q: nil, root: nil, height: nil)
    @height = height
    @root_node = Node.new value:root, parent:self
    @root_level = Level.new nodes:[@root_node]
    @root_levels = Levels.new levels:[@root_level] 
    @tree_levels = { 0 => @root_levels }
    @tracer = CTracer.new p:p, q:q, now:@root_node.value
    set_up
  end

  def set_up
    (1..@height).each{|i| @tree_levels[i] = Levels.new(parent:@tree_levels[i-1].levels) }
    (0..(@height-1)).each{|i| @tree_levels[i].child = @tree_levels[i+1].levels }
    idx = 0
    while idx < @height do
      @tree_levels[idx].each_node{|node|
        @tracer.now = node.value
        @tree_levels[idx+1].push node.make_child @tracer
      }
      idx += 1
    end
  end

  def each
  end

  def validate_q
    raise CTValidateQError, "#{@q.to_s} does not have #{@r} elements" if @q.length != @r
    std_q = [0] + (1..(@r-1)).to_a.reverse
    wrong_pairs = (std_q.zip(@q))[1..-1].reject{|p| (p[1] == p[0]) or ((p[1]-p[0]) % @r == 0) }
    if wrong_pairs.size > 0
      raise CTValidateQError, "#{@q.to_s} have wrong elements : #{wrong_pairs.map{|pair| pair[1] }.to_s}"
    end
  end  

  def modify_q index, value
    @q[index] = value
  end

  def type
    @now % @p
  end

  def branches
    (1..(@r-1)).to_a.select{|direction|
      div, mod = (@now - @q[direction]).divmod @p
      mod == 0 and ((div * @p) + @q[div % @r]) == @now
    }.size + 1
    # + 1 because up branch for direction-0 always exists  
  end

  def up
    return (lambda{|direction|
      return @now = @now * @r if direction == 0
      div, mod = (@now - @q[direction]).divmod @p
      raise CTStandardError if div == 0
      if mod == 0 and ((div * @p) + @q[div % @r]) == @now
        @now = div
      else
        raise CTDirectionError, "can not go to #{direction}"
      end
    })
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

  def to_gexf level
    @required_level = level
    graph = GEXF::Graph.new
    graph.define_node_attribute(:value, :type => GEXF::Attribute::INTEGER)
    graph.define_node_attribute(:level, :type => GEXF::Attribute::INTEGER)
    graph.define_node_attribute(:reach, :type => GEXF::Attribute::INTEGER)
    graph.define_node_attribute(:left_reach, :type => GEXF::Attribute::INTEGER)
    graph.define_node_attribute(:expression, :type => GEXF::Attribute::STRING)
    graph.define_node_attribute(:rightable, :type => GEXF::Attribute::BOOLEAN, :default => false)

    @nodes = []
    @nodes[0] = graph.create_node(:label => @now.to_s)
    @nodes[0][:value] = @now
    @nodes[0][:level] = 0
    @nodes[0][:reach] = 0
    @nodes[0][:left_reach] = 0
    @expr_hash[@now] = @now.to_s
    @nodes[0][:expression] = @expr_hash[@now]
    @prev_value = @now
    forward
    while @current_level > 0
      if @prev_move == 'L' or @prev_move == 'R'
        node = graph.create_node(:label => "#{@now.to_s}")
        node[:value] = @now
        node[:level] = @current_level
        node[:reach] = @current_reach
        node[:left_reach] = @left_reach
        node[:expression] = @expr_hash[@now]
        prev_node = @nodes.find{|n| n[:value] == @prev_value }
        prev_node.connect_to node if prev_node
        if @prev_move == 'R'
          prev_node[:rightable] = true
        end
        @nodes.push node
      end
      forward
    end
    graph.to_xml
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
      @prev_value = @now
      case @prev_move
      when 'L'
        up_left
        @prev_move = 'L'
        @current_level += 1
        @left_reach += 1
      when 'l'
        if up_rightable?
          up_right
          @prev_move = 'R'
          @current_level += 1
          @prev_reach.push @current_reach
          @max_reach += 1
          @current_reach = @max_reach 
        else
          if down_leftable?
            down_left
            @prev_move = 'l'
            @current_level -= 1
            @left_reach -= 1
          else
            down_right
            @prev_move = 'r'
            @current_level -= 1
            @current_reach = @prev_reach.pop
          end
        end
      when 'r'
        down_left
        @prev_move = 'l'
        @current_level -= 1
        @left_reach -= 1
      when 'R'
        up_left
        @prev_move = 'L'
        @current_level += 1
        @left_reach += 1
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
          @left_reach -= 1
        when 'R'
          down_right
          @prev_move = 'r'
          @current_level -= 1
          @current_reach = @prev_reach.pop
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
       # @expression = "((#{@prev_expression})-#{@q[div % @r]})/#{@p.to_s}"
        @expr_hash[@up_right] = "((#{@expr_hash[@prev_value]})-#{@q[div % @r]})/#{@p.to_s}"
        return true
      end
    }
    @up_right = nil
    return false
  end

  def up_left
    @now = @now * @r
    @expr_hash[@now] = "#{@r.to_s}*(#{@expr_hash[@prev_value]})"
  end

  def down_right
    supplement = @q[@now % @r]
    @now = @p * @now + supplement
    # @expression = "#{@r.to_s}*(#{@prev_expression})+#{supplement.to_s})"
  end

  def down_left
    @now = @now / @r
    # @expression = "(#{@prev_expression})/#{@r.to_s}"
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
=begin
  (3651..15000).each{|p|
    puts "  start check p: #{p}"
    find_loops p
  }
=end
  t = CTracer.new(p:4, now:63, q:[0, 2, 1])
  puts t.to_gexf 7
end
