#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# gen_loop_patterns.rb

class Patterns
  def initialize p:p, len:len
    @p = p
    @r = p - 1
    @len = len
    @base_array = []
  end
  attr_accessor :p, :len
  attr_reader :base_array

  def generate_base
    @base_array = ((@r**(@len-1))..(@r**@len-1)).to_a.map{|n| n.to_s @r }
  end

  def delete_series_of_nonzero_digit
    @base_array.delete_if{|s| /[^0][^0]+/ =~ s }
  end

  def delete_if_both_side_is_nonzero_digit
    @base_array.delete_if{|s| s[0] != '0' and s[-1] != '0' }
  end

  def rotate_duplication_check
    tmp = @base_array.clone
    tmp.each{|s|
      cnt = 1
      rot = s.split('').rotate.join()
      while cnt < s.size and (!@base_array.include?(rot) or rot == s) do
        # 生き残ってほしい条件をあげている。rot == s とあるのがミソ。
        # lenが偶数のときrotateにより自分に一致してしまうことがある。
        # それは消してはいけないのである。
        cnt+=1
        rot = rot.split('').rotate.join()
      end
      @base_array.delete s if cnt < s.size
    }
  end  

  def return_array
    generate_base
    delete_series_of_nonzero_digit
    delete_if_both_side_is_nonzero_digit
    rotate_duplication_check
    return @base_array
  end
end

if __FILE__ == $0
  p = Patterns.new(p:ARGV[0].to_i, len:ARGV[1].to_i)
  puts p.return_array
end

