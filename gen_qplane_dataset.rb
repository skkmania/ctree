#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# gen_qplane_dataset.rb
#
#  p4_qformula_collection.txtを読み
#  x == q1 / 5
#  のような式にあてはまる整数解を
#  QRangeから探し、出力する
#

require 'fileutils'
require 'optparse'
require 'prime'
require 'logger'
require "google_drive"
require './ctracer.rb'
require './qrange.rb'

class QplaneData

  def initialize(p, q, tgt, ofile)
    @p = p
    @q = q
    @q_count = 0
    @next_q_bound = 10**(@p-2)
    @tgt = tgt if tgt
    # @of = open(ofile,'w+') if ofile
    @of = nil
    @headers = "p,q(abbrev),pattern,num of 0 in pattern,min of tgts,<- length,<-index,comp ratio,max move-0 length,tgt after max 0-move,process time,tgt".split(",")
    @pass_list = []
    @output_limit_size = @tgt.to_s.size * 0.75
  end
  attr_accessor :p, :q, :tgt, :of, :q_count, :next_q_bound, :moves_history, :q_ranges, :q_index, :q_index_ranges, :output_limit_size 
  attr_reader  :trail, :pass_list

  def go_steps n
    @moves_history = []
    @trail = [@tgt]
    @ct = CTracer.new p:@p, q:@q, now:@tgt
    cnt = 0
    while (cnt < n) or (@ct.prev_down_move == 0)  do
      @ct.down
      @trail.push @ct.now
      @moves_history.push @ct.prev_down_move
      cnt += 1
    end
  end

  # tgtがstepをたどったとき、move-0 の連続が最大何度あったか
  #   move-0 とは、tgtを@rで割る操作のこと
  #   返り値: [ 最大の連続数、それを経た直後のtgtの値 ]
  def max_0_len
    len = max_len = max_len_idx = 0
    @moves_history.each_with_index{|e, idx|
      if e == 0
        len += 1
      else
        len = 0
      end
      if len >= max_len
        max_len = len
        max_len_idx = idx
      end
    }
    return [max_len, @trail[max_len_idx+1]]
  end


  def output dst
    max_len, v_after_max_len = max_0_len
    # ratio = sprintf "%0.9f", (@trail.min * 1.0)/@tgt
    #row_array = [[@p, abbrev_q, @moves_history.to_s, @moves_history.count(0), @trail.min, @trail.min.to_s.size,ratio, max_len, v_after_max_len, (@t1.utime-@t0.utime).to_s]]
    min_of_tgts = @trail.min
    return if min_of_tgts.to_s.size > @output_limit_size
    row_array = [[@p] +  [@moves_history.to_s, @moves_history.count(0), min_of_tgts, min_of_tgts.to_s.size,@trail.index(min_of_tgts), max_len, v_after_max_len ] + @q[1..-1] ]
    case dst
    when 'google'
    else
      @of.puts row_array[0].join(":")
    end
  end


  # @qを全部出力するのは長すぎるので
  # default_qと異なるところだけ出力する
  def abbrev_q
    return 'default' if @q == default_q
    cnt = 0
    default_q.zip(@q).inject(""){|mem, a|
      mem += "#{cnt}=>#{a[1]}, " if (a[0] != a[1]); cnt += 1;  mem
    }
  end

  def search_prime_factor tgt
    ret = []
    Prime.each(10000){|p|
      i=1;x=p
      while (tgt%x)==0
        i+=1;x*=p
      end
      ret.push [p,i-1]
    }
    ret
  end

  def chk_non_effective_q
    ((0..(@p-2)).to_a - @moves_history[0..-2]).map{|n| p-1-n }
  end

  def make_pass_list
    nefq = chk_non_effective_q
    (1..(10**nefq.size - 1)).to_a.each{|n|
      digits = sprintf("%0#{nefq.size}d",n).split('').map(&:to_i)
      pass_num = (nefq.zip(digits)).inject(0){|total,ar| total += ar[1]*(10**(ar[0]-1));total }
      @pass_list.push(@q_count + pass_num)
    }
  end
end


def bbbb
  f = open('data/p4_dataset.txt')
  lines = f.readlines
  dar_txt = lines.map{|line| line.chomp.split(':')[1] }
  dar = dar_txt.map{|l| eval l }
  q_stat = []
  101.times{ q_stat.push [0]*101 }
  dar.each{|ar| ar.each{|q| q_stat[(q[1]-2)/3][(q[2]-1)/3] += 1 } }
  f.close()
  return q_stat
end

def write_to_gdrive q_stat
  conf_file = '.googledrive.conf'
  lines = open(conf_file).readlines.map{|l| l.chomp }
  address = lines[0].split(':')[1]
  pwd = lines[1].split(':')[1]
  key = lines[4].split(':')[1] # num_of_loops_table
  session = GoogleDrive.login(address, pwd)
  ws = session.spreadsheet_by_key(key).add_worksheet DateTime.now.strftime('%Y%m%d_%H%M')
  ws.update_cells(1, 1, [[""] + (0..100).to_a] )
  cnt = 0
  q_stat.each{|row|
puts [[cnt] + row].to_s
    ws.update_cells(cnt+2, 1, [[cnt] + row])
    ws.save()
    cnt += 1
  }
  ws.save()
end

def write_single_to_gdrive pat, ary
  conf_file = '.googledrive.conf'
  lines = open(conf_file).readlines.map{|l| l.chomp }
  address = lines[0].split(':')[1]
  pwd = lines[1].split(':')[1]
  key = lines[4].split(':')[1] # num_of_loops_table
  session = GoogleDrive.login(address, pwd)
  ws = session.spreadsheet_by_key(key).add_worksheet 'p4_'+pat
  ws.update_cells(1, 1, [[""] + (0..100).to_a] )
  ws.update_cells(1, 1, [[""]] + (0..10).map{|i| [i] } )
  ary.each{|q|
    q1 = (q[1]-2)/3
    q2 = (q[2]-1)/3
    ws.update_cells(q1+1, q2+1, [[1]])
  }
  ws.save()
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
=begin
  ds.keys.each{|k|
    puts "#{k}:#{ds[k]}"
  }
=end
  write_to_gdrive q_stat
end
