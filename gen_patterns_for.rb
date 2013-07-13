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
    @base_hash = Hash.new{|h,k| h[k] = Array.new }
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
      next if plus_minus_check pat
      key = pat.chars.sort.join
      @base_hash[key].push pat
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

  #
  # loopなので、素材の2つが循環して同じならひとつだけ残せばよい
  #
  def rotate_duplication_check
    @base_hash.each{|k,ar|
      tmp = ar.clone
      tmp.each{|s|
        cnt = 1
        rot = s.split('').rotate.join
        while cnt < s.size and (!ar.include?(rot)) do
          cnt+=1
          rot = rot.split('').rotate.join
        end
        ar.delete s if cnt < s.size
      }
    }
  end  

  #
  # pattern中の0の個数と非0の個数とpから、xの正負を判断し負なら捨てる
  #
  def plus_minus_check pat
       zero = pat.count("0")
       non_zero = pat.size - zero
       @p**non_zero > @r**zero
  end

  def return_hash
    generate_base
    rotate_duplication_check
    return @base_hash
  end
end

if __FILE__ == $0
  n0 = ARGV[0].to_i
  n1 = ARGV[1].to_i
  ps = Patterns.new n0, n1
  ps.return_hash.each{|k,ar|
    ar.each{|pat|
      puts "#{pat}"
    }
  }
end

