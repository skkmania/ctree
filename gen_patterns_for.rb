#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# gen_patterns_for.rb
#   p = 3 を前提。
#   #0, #1を指定し、ありうる全てのloopのpatternを出力する
#  Usage:
#    gen_patterns_for.rb #0 #1
#

class Patterns
  def initialize n0, n1
    @p = 3
    @r = 2
    @n0 = n0
    @n1 = n1
    @len = n0 + n1
  end
  attr_accessor :len
  attr_reader :base_hash

  #
  #  まずpatternの素材をつくっておく。
  #    @len - 1 
  #  後でここからpatternではないものを取り除いて最終報告とする
  def generate_base
    (1..@n0-1).to_a.combination(@n1-1).each{|ar|
      prev = 0
      pat = ar.inject("10"){|mem,e| mem = mem + "0"*(e - prev - 1) + "10"; prev = e; mem }
      pat = pat + "0"*(@len - pat.size) 
      next if check_if_cycle_occurs pat
      puts pat
    }
  end

  #
  # loopの内部でくりかえしがあってはならない
  # 例: 100100 では 100 がくりかえしている。このようなpatternは長さ6のpattern
  # ではなく、長さ3のpatternとして扱われなければならない
  #
  def check_if_cycle_occurs pat
       md = pat.match(/(\d+)\1+/)
       unless md
         false  #  くりかえしがないなら消さない
       else
         md.offset(0) == [0, pat.size] # くりかえしがsの始めから最後までを占めているなら消す
       end
  end

end

if __FILE__ == $0
  n0 = ARGV[0].to_i
  n1 = ARGV[1].to_i
  if 2**n0 - 3**n1 < 0
    puts "aborting: 2**#{n0} - 3**#{n1} must be positive."
    exit
  end
  ps = Patterns.new n0, n1
  ps.generate_base
end

