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
#     p = 6 と p = 7 
require 'fileutils'
require 'optparse'
require 'prime'
require 'logger'
require "google_drive"
require './ctracer.rb'

class Array
  # 指定した要素の次の要素(末尾の次は先頭)を
  # 先頭に戻ったときはtrueとともに
  # 通常はfalseとともに
  # 配列にして返す。(くりあがり演算の補助が目的)
  def next_to e
    return nil if size == 0
    pos = index e
    return nil unless pos
    return [true, at(0)] if pos == size - 1
    [false, at(pos + 1)]
  end
end

class TryOut

  def initialize(p, q, tgt, ofile)
    @p = p
    @q = q
    @q_index = q_to_q_index
    @q_ranges = {}
    @q_index_ranges = default_q_index_ranges
    @q_count = 0
    @next_q_bound = 10**(@p-2)
    @tgt = tgt if tgt
    # @of = open(ofile,'w+') if ofile
    @of = nil
    @headers = "p,q(abbrev),pattern,num of 0 in pattern,min of tgts,<- length,<-index,comp ratio,max move-0 length,tgt after max 0-move,process time,tgt".split(",")
    @t0 = Process.times
    @t1 = Process.times
    @pass_list = []
    @output_limit_size = @tgt.to_s.size * 0.75
  end
  attr_accessor :p, :q, :tgt, :of, :q_count, :next_q_bound, :moves_history, :q_ranges, :q_index, :q_index_ranges, :output_limit_size 
  attr_reader  :trail, :pass_list

  def default_q
    [0] + (1..(@p-2)).to_a.reverse
  end

  def q_to_q_index
    (@q.zip(default_q)).map{|a| (a[0] - a[1])/(@p - 1) }
  end

  def q_index_to_q
    (@q_index.zip(default_q)).map{|a| a[1] + (@p - 1)*a[0] }
  end

  def set_q_index_ranges str
    @q_index_ranges.update eval(str)
    (1..(@p-2)).to_a.each{|n| @q_index[n] = @q_index_ranges[n][0] }
  end 

  def default_q_index_ranges
    ret = { 0 => [] }
    (1..(@p-2)).to_a.each{|n| ret[n] = (0..9).to_a }
    ret
  end 

  def set_default p
    @p = p
    @q = default_q
    @q_index = q_to_q_index
    @q_index_ranges = default_q_index_ranges
    @q_count = 0
    @next_q_bound = 10**(@p-2)
  end

  def go_steps n
    @t0 = Process.times
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
    @t1 = Process.times
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

  def count_to_q
    ar = [0] + sprintf("%0#{@p-2}d",@q_count).split('').map(&:to_i)
    def_q = default_q 
    (1..(@p-2)).to_a.each{|i|
      @q[i] = (@p - 1)*ar[i] + def_q[i] 
    }
  end

  def next_q
    return nil if @q_count == @next_q_bound
    @q_count +=1
    while @pass_list.include? @q_count
      @pass_list.delete @q_count
      @q_count +=1
    end
    count_to_q
  end

  def count_to_q_index
  end

  def next_q_index
    cnt = @p - 2
#puts "cnt: #{cnt}, q_index_ranges: #{@q_index_ranges.inspect}"
    tmp = @q_index_ranges[cnt].next_to @q_index[cnt]
#puts "tmp: #{tmp.inspect}"
    @q_index[cnt] = tmp[1]
#puts "q_index: #{@q_index.inspect}"
    while tmp[0] and cnt > 0
      cnt -= 1
      return nil if cnt == 0 # 最後までくりあがりきったことになるので。
      tmp = @q_index_ranges[cnt].next_to @q_index[cnt]
      @q_index[cnt] = tmp[1]
    end
    true
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
    to.set_q_index_ranges opts[:q_index_ranges] if opts[:q_index_ranges] 
    to.of = open("#{o_filename}_t#{tgt.size}_p#{p}.csv",'w+') if ARGV[0] != 'google'
    while to.next_q_index do
      to.q = to.q_index_to_q
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
