#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#
#  pattern_to_exp.rb :
#    convert a loop pattern to a tree of expression 
#

class Parser
  def initialize p:3, q:nil, pat:""
    @p = p
    @r = p - 1
    @q = (q ? q : [0] + (1..(@p-2)).to_a.reverse )
    @pattern = pat
    @tree = []
  end
  attr_accessor :p, :q, :pattern
  attr_reader :tree

  def parse str=nil
    @pattern = str if str 
    @tree = @pattern.chars.map(&:to_i).inject([]){|tree, i|
      ret = []
      if tree.size == 0
        if i == 0
          ret = [:div, :x, @r]
        else
          ret = [:+, [:*, @p, :x], @q[i] ]
        end
      else
        if i == 0
          ret = [:div, tree, @r]
        else
          ret = [:+, [:*, @p, tree], @q[i] ]
        end
      end
      ret
    }
  end

  def tracable? x
    tgt = x
    @pattern.chars.map(&:to_i).each{|i|
      if i == 0
        return false if tgt % @r != 0
        tgt = tgt / @r
      else
        return false if tgt % @r != i
        tgt = @p * tgt + @q[i]
      end
    }
    return true
  end

  def evaluate x
    # raise "#{x} cannot trace pattern: #{@pattern}" unless tracable? x
    return false unless tracable? x
    @x = x
    eval_single @tree
  end

  def eval_single ary
    op = ary[0]
    left  = if ary[1].is_a?(Array)
              eval_single ary[1]
            elsif ary[1] == :x
              @x
            else
              ary[1]
            end
    right = if ary[2].is_a?(Array)
              eval_single ary[2]
            elsif ary[2] == :x
              @x
            else
              ary[2]
            end
    case op
    when :*
      return left * right
    when :+
      return left + right
    when :div
      return left / right
    end
  end

  def loop_check x
    x == evaluate(x)
  end
end

if __FILE__ == $0
  p = Parser.new p:4, q:[0,2,1]
  p.parse("1010")
  puts p.tree.to_s
  ans = p.evaluate 10
  puts ans.to_s
end

