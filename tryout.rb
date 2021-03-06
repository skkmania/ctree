#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# tryout.rb
#
# ある数が、30step downするあいだにどのくらい小さくなるものか、を見るためのスクリプト
#    p,q をある範囲で動かして、ひたすら実際にpn + qの規則にのっとり計算させ、30step内の最小値などを報告する
#    報告先はファイルを指定する。(GoogleDriveのspreadsheetを指定することも可能。)
# Usage:
#  default値を最大に使用するケース
#  ruby tryout.rb -t ある数x(30ケタ程度のものを想定している) -o 出力先ファイル名
#    こうすると、
#     p = 6 と p = 7 について計算する。qはdefaultから始まり 
#

require 'fileutils'
require 'optparse'
require 'prime'
require 'logger'
require "google_drive"
require './ctracer.rb'
require './qrange.rb'

class TryOut

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

  def set_google conf_file
    lines = open(conf_file).readlines.map{|l| l.chomp }
    address = lines[0].split(':')[1]
    pwd = lines[1].split(':')[1]
    key = lines[3].split(':')[1]
    @address = address
    @pwd = pwd
    @key = key
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
      last_row = @ws.num_rows + 1
      @ws.update_cells(last_row,1,row_array)
      @ws.save()
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

  def add_sheet name
    @session = GoogleDrive.login(@address, @pwd)
    @ws = @session.spreadsheet_by_key(@key).add_worksheet name
    @ws.update_cells(1,1,[@headers])
    @ws[2,9] = @tgt
      # google spreadsheet ではruby のIntegerを文字列にしている
    @ws.save()
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
  o_filename = opts[:o_file]
  qr = QRange.new 4, [0,2,1], opts
  tgt = opts[:target]
  to = TryOut.new(4, [0,2,1], tgt, o_filename)
  to.tgt = tgt
  to.output_limit_size = opts[:limit_size]
  p_start = opts[:p_start] || 6
  p_end = opts[:p_end] || 7
  if o_filename == 'google'
    to.set_google '.googledrive.conf'
    to.add_sheet DateTime.now.strftime('%Y%m%d_%H%M')
  end
  down_steps = opts[:steps] || 30
  puts "processe starts."
  (p_start..p_end).each{|p|
    to.set_default p
    to.of = open("#{o_filename}_t#{tgt.size}_p#{p}.csv",'w+') if ARGV[0] != 'google'
    qr.each_q do |q|
      to.q = q
      to.go_steps down_steps
      # to.make_pass_list
      to.output o_filename
      # print "\r processing #{to.q_count}" # if to.q_count % 100 == 0
    end
    puts "p : #{p} has been processed."
    to.of.close if ARGV[0] != 'google'
  }
  puts
end
