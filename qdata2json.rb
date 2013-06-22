#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# qdata2json.rb
# qdataをjson fileとして出力する
#
require 'json'
require 'pathname'
require Pathname(__FILE__).expand_path.dirname.to_s +  '/gen_loop_patterns.rb'
require Pathname(__FILE__).expand_path.dirname.to_s +  '/qrange.rb'

class QD2JS
  attr_accessor :p, :len
  def initialize(p:p, len:len, opt:{})
    @p = p
    @len = len 
    @patterns = Patterns.new(p:@p, len:@len).return_array
    @q_index_ranges = opt[:q_index_ranges] || { 0 => [0] }
    @qr = QRange.new @p, {:q_index_ranges => @q_index_ranges}
  end

  def pat2expr str
    ret = str.chars.inject("x"){|mem, c|
      case c
      when '0'
        mem = "(#{mem})/r"
      else
        mem = "p*(#{mem})+q[#{c}]"
      end
    }
    ret
  end

  def expr2lambda str
    eval "->(x, p, q, r){ #{str} }"
  end

  def search_q lmd
    ret = []
    @qr.each{|q|
      ret.push q if x == lmd.call(x,@p,q,@p-1)
    }
    ret
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
