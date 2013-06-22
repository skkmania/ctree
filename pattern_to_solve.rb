#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# pattern_to_solve.rb
# patternからexpressionを生成し、maximaのsolve文をつくる
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

  def pat2expr_for_solve str
    ret = str.chars.inject("x"){|mem, c|
      case c
      when '0'
        mem = "(#{mem})/r"
      else
        mem = "p*(#{mem})+q#{c}"
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
  open(ARGV[0],'r'){|f|
    f.each_line{|line|
      p, len, id, pattern = line.chomp!.split(',')
      qj = QD2JS.new p:p.to_i, len:len.to_i
      expr = qj.pat2expr_for_solve pattern
      # solve = "solve([x == #{expr}],x)"
      puts "#{line},#{expr}"
    }
  }
end
