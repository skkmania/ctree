#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# recursive_pattern_gen.rb
require 'json'
require 'pathname'
require Pathname(__FILE__).expand_path.dirname.to_s +  '/gen_loop_patterns.rb'

class PGen
  def initialize(p:p, now:root)
    @p = p
    @r = @p - 1
    @now = now
    @checker = Patterns.new p:p, len:@now.size
  end
  attr_accessor :now

  def check_pattern pat
       @checker.check_series_of_nonzero_digit pat\
    or @checker.check_if_both_side_is_nonzero_digit pat\
    or @checker.check_if_00_not_found pat\
    or @checker.check_if_cycle_occurs pat
   # or @checker.plus_minus_check pat 
  end

  def ups
    if @now[-1] == '0'
      (0..@r-1).map{|c| "#@now#{c}" }
    else
      [@now+'0']
    end
  end
end

class PatternTree
  include Enumerable
  attr_accessor :height, :ptree
  def initialize(p:p, q:q, root:root, height:height)
    @height = height
    @tracer = PGen.new p:p, now:root
    @ptree = set_up(0, root)
  end

  def set_up(lvl, now)
    return nil if lvl > @height
    ret = {}
    ret["data"] = now
    ret["valid"] = !(@tracer.check_pattern now)
    ret["children"] = []
    @tracer.now = now
    @tracer.ups.each{|v|
      new_hash = set_up(lvl+1, v)
      ret["children"].push(new_hash) if new_hash
    }
    return ret
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
  t = CCTree.new(p:4, q:[0, 2, 1], root:63, height:10)
  t.pp
end
