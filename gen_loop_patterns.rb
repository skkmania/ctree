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
    @base_hash = Hash.new{|h,k| h[k] = Array.new }
  end
  attr_accessor :p, :len
  attr_reader :base_hash

  #
  #  まずpatternの素材をつくっておく。
  #  後でここからpatternではないものを取り除いて最終報告とする
  #  0で始まるものは後で取り除くのが確実なのではじめから生成しない
  #  素材例 : r = 3, len = 3 のとき 3**2 から 3**3ー1までを3進法表記で生成する
  #    100, 101, 102, 120, 121, 122, 200, 201, 202, 210, 211, 212, 220, 221, 222
  def generate_base
    ((@r**(@len-1))..(@r**@len-1)).each{|n|
      pat = n.to_s @r
      next if check_series_of_nonzero_digit pat
      next if check_if_both_side_is_nonzero_digit pat
      next if check_if_00_not_found pat
      next if check_if_cycle_occurs pat
      next if plus_minus_check pat
      key = pat.chars.sort.join
      @base_hash[key].push pat
    }
  end

  #
  # patternには0以外の数字が続くことはない
  #
  def check_series_of_nonzero_digit pat
    /[^0][^0]+/ =~ pat
  end

  #
  # 上と同じ意味で、循環することを考えると、両端が同時に0以外の数字ではいけない
  #
  def check_if_both_side_is_nonzero_digit pat
    pat[0] != '0' and pat[-1] != '0'
  end

  #
  # loopにはすくなくとも1ヶ所は00と続くところがあらねばならない
  #
  def check_if_00_not_found pat
    pat.index('00') == nil
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
  p = ARGV[0].to_i
  len = ARGV[1].to_i
  ps = Patterns.new(p:p, len:len)
  ps.return_hash.each{|k,ar|
    ar.each_with_index{|pat, idx|
      puts "#{p},#{len},#{idx},#{pat}"
    }
  }
end

