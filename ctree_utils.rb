#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# ctree_utils.rb
#
#  pryに読み込みinteractiveに使えるtoolを集める
#

require 'fileutils'
require 'logger'
require 'prime'
require './ctracer.rb'

Log = Logger.new 'log/ctree_utils.log'

class CTUtils
  def initialize(p:3, opt:{})
    @p = p
    @r = @p - 1
    @collection = opt[:collection]
    @spreadsheet = opt[:spreadsheet]
    @top_left = opt[:top_left]
    @patterns = {}
    @row_count = 3000
  end
  attr_accessor :p, :collection, :spreadsheet, :opt, :patterns
  attr_reader :session, :ws, :key

  def start_gdrive
    conf_file = './.googledrive.conf'
    lines = open(conf_file).readlines.map{|l| l.chomp }
    @address = lines[0].split(':')[1]
    @pwd = lines[1].split(':')[1]
    @key = lines.find{|line| line.split(':')[0] == @spreadsheet }.split(':')[1] 
    get_ws
  end

  def get_ws
    @session = GoogleDrive.login(@address, @pwd)
    @ws = @session.spreadsheet_by_key(@key).worksheets[0]
  end

  def put_q_labels
    q_ary = (0..@row_count).map{|i| [2*i + 1] }
    @ws.update_cells(@top_left[0], @top_left[1]-1, q_ary)
    @ws.save()
  end

  def read_pattern_and_formula len
    open(@collection).readlines.each_slice(8){|lines|
      pat = lines[0].chomp
      break if pat.size > len
      next if lines[6].include?('-')
      @patterns[pat] = lines[6].chomp.gsub("q1","q").gsub("==","=")
    }
  end

  def put_formula_labels
    rows = ["", [@patterns.keys.map(&:size)],
                [@patterns.keys],
                [@patterns.values]
           ]
    (1..3).each{|r| @ws.update_cells(r, 2, rows[r]) }
    @ws.save()
  end

  def put_loops r, c, a, b, pat
    column = (0..@row_count).map{|i| 2*i + 1 }.map{|q|
               init, mod = (b*q).divmod a
               mod == 0 ? [expand(q,pat,init)] : [] }
    @ws.update_cells(r, c, column) 
    @ws.save()
  end

  def put_all
    cnt = 2
    @patterns.each{|pat, formula|
      b, a = read_formula(formula)
      if !b || !a
        Log.error "#{pat}, #{formula}, #{cnt}, something wrong"
        next
      else
        put_loops 6, cnt, a, b, pat
        cnt += 1
      end
    }
  end

  def read_formula formula
    ret = formula.scan(/ (\d+)\/(\d+)\*/).flatten.map(&:to_i)
    ret.size == 0 ? [1,1] : ret
  end

  def expand(q, pat, init)
    e_mes = ""
    x = init
    ret = pat[0..-2].chars.inject([init]){|mem, c|
      if c == '1'
        e_mes += "#{x} coreced to 1. " if x % @r == 0
        x = @p*x + q
      else
        e_mes += "#{x} coreced to 0. " if x % @r != 0
        x = x/@r
      end
      mem.push x
    }
    puts e_mes if e_mes.size > 0
    ret
  end
end

if __FILE__ == $0
end
