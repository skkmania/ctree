#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# gen_loop_patterns.rb
#   p と長さを指定し、ありうる全てのloopのpatternを出力する
#   

class Patterns
  def initialize p:p, len:len
    @p = p
    @r = p - 1
    @len = len
    @base_array = []
  end
  attr_accessor :p, :len
  attr_reader :base_array

  #
  #  まずpatternの素材をつくっておく。
  #  後でここからpatternではないものを取り除いて最終報告とする
  #  0で始まるものは後で取り除くのが確実なのではじめから生成しない
  #  素材例 : r = 3, len = 3 のとき 3**2 から 3**3ー1までを3進法表記で生成する
  #    100, 101, 102, 120, 121, 122, 200, 201, 202, 210, 211, 212, 220, 221, 222
  def generate_base
    @base_array = ((@r**(@len-1))..(@r**@len-1)).to_a.map{|n| n.to_s @r }
  end

  #
  # patternには0以外の数字が続くことはない
  #
  def delete_series_of_nonzero_digit
    @base_array.delete_if{|s| /[^0][^0]+/ =~ s }
  end

  #
  # 上と同じ意味で、循環することを考えると、両端が同時に0以外の数字ではいけない
  #
  def delete_if_both_side_is_nonzero_digit
    @base_array.delete_if{|s| s[0] != '0' and s[-1] != '0' }
  end

  #
  # loopにはすくなくとも1ヶ所は00と続くところがあらねばならない
  #
  def delete_if_00_not_found
    @base_array.delete_if{|s| s.index('00') == nil }
  end

  #
  # loopの内部でくりかえしがあってはならない
  # 例: 100100 では 100 がくりかえしている。このようなpatternは長さ6のpattern
  # ではなく、長さ3のpatternとして扱われなければならない
  #
  def delete_if_cycle_occurs
    @base_array.delete_if{|s|
       md = s.match(/(\d+)\1+/)
       unless md
         false  #  くりかえしがないなら消さない
       else
         md.offset(0) == [0, s.size] # くりかえしがsの始めから最後までを占めているなら消す
       end
    }
  end

  #
  # loopなので、素材の2つが循環して同じならひとつだけ残せばよい
  #
  def rotate_duplication_check
    tmp = @base_array.clone
    tmp.each{|s|
      cnt = 1
      rot = s.split('').rotate.join()
      while cnt < s.size and (!@base_array.include?(rot)) do
        cnt+=1
        rot = rot.split('').rotate.join()
      end
      @base_array.delete s if cnt < s.size
    }
  end  

  #
  # pattern中の0の個数と非0の個数とpから、xの正負を判断し負なら捨てる
  #
  def plus_minus_check
    @base_array.delete_if{|s|
       zero = s.count("0")
       non_zero = s.size - zero
       @p**non_zero > @r**zero
    }
  end

  def return_array
    generate_base
    delete_series_of_nonzero_digit
    delete_if_both_side_is_nonzero_digit
    delete_if_00_not_found
    delete_if_cycle_occurs
    rotate_duplication_check
    plus_minus_check
    return @base_array
  end
end

if __FILE__ == $0
  p = ARGV[0].to_i
  len = ARGV[1].to_i
  ps = Patterns.new(p:p, len:len)
  ps.return_array.each_with_index{|pat,idx|
    puts "#{p},#{len},#{idx},#{pat}"
  }
end

