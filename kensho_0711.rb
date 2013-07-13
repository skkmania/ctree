#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#   kensho_0711.rb
#   data/p3_loops
#   にあるfileをある観点から検証する
#   このスクリプトは使い捨て
#   
require 'prime'

class Register
  def initialize fname
    @fname = fname
  end
  attr_accessor :fname


  def process
    open(@fname).readlines.each_slice(10){|lines|
      q = lines[1].chomp.split(': ')[1].to_i
      # qid = lines[2].chomp.split(': ')[1]
      # size = lines[3].chomp.split(': ')[1]
      num_0 = lines[4].chomp.split(': ')[1].to_i
      num_1 = lines[5].chomp.split(': ')[1].to_i
      #loop_str = lines[8].chomp.split(': ')[1]
      #pattern = lines[9].chomp.split(': ')[1]
      kensho(q, num_0, num_1)
    }
  end

  # 最大公約数
  def gcd(a, b)
    return a if b == 0
    gcd(b, a % b)
  end

  def kensho q, n0, n1
    d = (2**n0 - 3**n1)
    div, mod = d.divmod q
    if mod == 0
      puts " 1: denom:#{d} = q:#{q} * #{div}"
    else
      div, mod = q.divmod d
      if mod == 0
        puts " 2: q:#{q} = denom:#{d} * #{div}"
      else
        g = gcd(q,d)
        puts " 3: gcd:#{g}, q:#{q} = #{g} * #{q/g}, denom:#{d} = #{g} * #{d/g}"
      end
    end
  end
end

if __FILE__ == $0
  fname = ARGV[0]
  rg = Register.new fname
  rg.process
end

