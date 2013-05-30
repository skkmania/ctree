#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# compact_ctree.rb
require 'json'
require 'pathname'
require Pathname(__FILE__).expand_path.dirname.to_s +  '/ctracer.rb'

class CCTree
  include Enumerable
  attr_accessor :height, :cctree
  def initialize(p:p, q:q, root:root, height:height)
    @height = height
    @tracer = CTracer.new p:p, q:q, now:root
    @cctree = set_up(0, root)
  end

  def set_up(lvl, now)
    return nil if lvl > @height
    ret = {}
    ret["data"] = now
    ret["children"] = []
    @tracer.now = now
    @tracer.ups.each{|k,v|
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
