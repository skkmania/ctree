#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# ctree.rb
require './ctracer.rb'

class Node
  attr_accessor :value, :child, :parent, :prev_move, :mylevel
  def initialize value:nil, child:nil, parent: nil, prev_move:nil, mylevel:nil
    @value = (value ? value : 1)
    @child = (child ? child : nil)
    @parent = (parent ? parent : nil)
    @prev_move = (prev_move ? prev_move : nil)
    @mylevel = (mylevel ? mylevel : nil)
  end
  def mke_child tracer
    level = Level.new
    tracer.ups.each{|k, v|
      n = Node.new(value:v, parent:self, prev_move:k, mylevel:@mylevel+1)
      level.push n
    }
    level.parent = self
    @child = level
  end
  def is_a_same_node? node
    @value == node.value
  end
end

class Level
  include Enumerable

  attr_accessor :nodes, :child, :parent
  def initialize nodes:nil, child:nil, parent: nil
    @nodes = (nodes ? nodes : [])
    @child = child
    @parent = parent
  end

  def push x
    @nodes.push x
  end

  def each
    @nodes.each{|node|
      yield node
    }
  end
 
  def reject
    @nodes.each{|node|
      @nodes.delete node if (yield node)
    }
    self
  end

  def include_a_same_node? node
    @nodes.each{|n|
      return true if n.is_a_same_node? node
    }
    return false
  end

  def pp
    v_ary = @nodes.map{|n| n.value }
    print v_ary.to_s
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

  def push lvl
    @levels.push lvl
  end

  def each
    @levels.each{|level|
      yield level
    }
  end

  def each_node
    @levels.each{|lvl| lvl.each{|node| yield node } }
  end

  def include_a_same_node? node
    @levels.each{|lvl|
      return true if lvl.include_a_same_node? node
    }
    return false
  end

  def pp
    @levels.each{|level|
      level.pp
      print ", "
    }
  end

end

class CTree
  include Enumerable
  attr_accessor :tree_levels
  def initialize(p, q, root, height)
    @height = height
    @root_node = Node.new value:root, parent:self, mylevel:0
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
        lvl_candidat = node.make_child @tracer
        lvl = lvl_candidat.reject{|n| include_a_same_node? n } 
        @tree_levels[idx+1].push lvl if lvl.nodes.size > 0
      }
      idx += 1
    end
  end

  def each
    @tree_levels.each{|lvls|
      yield lvls
    }
  end

  def each_node
    @tree_levels.each{|idx, lvls|
      lvls.each{|lvl|
        lvl.each{|node| yield node }
      }
    }
  end

  def include_a_same_node? node
    @tree_levels.each{|idx, lvls|
      return true if lvls.include_a_same_node? node
    }
    return false
  end

  def pp
    @tree_levels.each{|idx,lvls|
      lvls.pp
      puts
    }
  end
end

if __FILE__ == $0
  t = CTree.new(p:4, q:[0, 2, 1], root:63, height:10)
  t.pp
end
