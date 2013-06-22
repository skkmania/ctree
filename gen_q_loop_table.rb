#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# gen_q_loop_table.rb
#
#  p3_qformula_collection.txtを読み
#  gdriveのp3_Q_Loop_Tableの内容を入力する
#

require 'fileutils'
require 'optparse'
require 'logger'
require "google_drive"

Log = Logger.new 'log/p3_gen_q_loop_table.log'

class QLoopTable
  def initialize(p:p, opt:{})
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
    x = init
    pat[0..-2].chars.inject(init.to_s){|mem, c|
      if c == '1'
        x = @p*x + q
      else
        x = x/@r
      end
      mem += ", #{x}"
    }
  end
end

if __FILE__ == $0
  opts = {}
  ARGV.options do |op|
    op.banner = "ruby #$0 [options] [args]"
    # op.separator "Ruby-like options:"
    op.on("-p integer", "--p_start", "start of p range"){|x| opts[:p_start] = x.to_i }
    op.on("-P integer", "--p_end", "end of p range"){|x| opts[:p_end] = x.to_i }
    op.on("-o string", "--o_file", "file name for output"){|x| opts[:o_file] = x }
    op.on("-s integer", "--steps", "number of steps down from target"){|x| opts[:steps] = x.to_i }
    op.on("-t integer", "--target", "target integer"){|x| opts[:target] = x.to_i }
    op.on("-l integer", "--limit_size", "output limit size"){|x| opts[:limit_size] = x.to_i }
    op.on("-q hash_literal", "--q_index_ranges", "q_index_ranges"){|x| opts[:q_index_ranges] = x }
    op.parse!
  end
  filename = ARGV[0]
  ds = {}
  q_stat = []
  q1_bound = 400
  q2_bound = 200
  q1_bound.times{ q_stat.push [0]*q2_bound }
  open(filename).readlines.each_slice(9){|lines|
    pat = lines[0].chomp
    ds[pat] = []
    ans = lines[7].chomp.gsub(/(\d+)\//,'\1.0/').gsub(/([pr])\^(\d+)/,'\1**\2')
    qr = QRange.new 4, {:q_index_ranges=>{1=>(0...q1_bound).to_a, 2=>(0...q2_bound).to_a}}
    qr.each{|q|
      q1 = (3*q[1]+2).to_f
      q2 = (3*q[2]+1).to_f
      xf = eval(ans[5..-1])
  #puts xf.to_s
      if xf.floor == xf
  print "\r found : q1:#{q1}, q2:#{q2}, q[1]:#{q[1]}, q[2]:#{q[2]}, ans: #{ans[5..-1].to_s}"
        ds[pat].push [0, q1.to_i, q2.to_i]
        q_stat[q[1]][q[2]] += 1
      end
    }
    puts "\n #{pat}: has #{ds[pat].size} q points"
    write_single_to_gdrive pat, ds[pat] if ds[pat].size > 0
    puts ds[pat][0..20].to_s
  }
  write_to_gdrive q_stat
end
