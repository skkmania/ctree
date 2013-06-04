#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# check_csv.rb
#
require 'fileutils'
require 'prime'
require './ctracer.rb'

open(ARGV[0]).each_line{|line|
  l2a = line.split(':')
  p = l2a[0].to_i
  hist = l2a[1][1..-2].split(',').map(&:to_i)
  puts line if ((0..(p-2)).to_a - hist).size > 0
}

