#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# q_formula_denominator_table.rb
#
#  q_formula の分母にくる r^m - p^m を数値で一覧する
#  同時に、その数値を因数分解した結果も一覧する
#  結果はgoogle_driveに保存する
#  ので、このスクリプト自体は使い捨ててよい
#

require "google_drive"
require "prime"


class QDenomTable
  def initialize p
    @p = p
    @r = @p - 1
    @spreadsheet = 'q_formula_denominator_table'
    @top_left = [2,2]
    @bound =  20
    @n_tbl = []
    @f_tbl = []
  end
  attr_accessor :p, :collection, :spreadsheet, :opt, :patterns
  attr_reader :session, :ws, :key

  def make_table
    (0..@bound).each{|m|
      @n_tbl[m] = Array.new
      @f_tbl[m] = Array.new
      (0..@bound).each{|n|
        denom = (@r**n - @p**m).abs
        @n_tbl[m][n] = denom
        @f_tbl[m][n] = denom.prime_division.to_s if denom != 0
      }
    }
  end

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
    @ws_num = @session.spreadsheet_by_key(@key).worksheets[1]
    @ws_den = @session.spreadsheet_by_key(@key).worksheets[2]
  end

  def put_labels
    m_ary = (0..@bound+30).map{|i| [i] }
    n_ary = (0..@bound+30).to_a
    [@ws_den,@ws_num].each{|ws|
      ws.update_cells(@top_left[0], @top_left[1]-1, m_ary)
      ws.update_cells(@top_left[0]-1, @top_left[1], [n_ary])
      ws.save()
    }
  end

  def put_all
    put_labels
    @ws_num.update_cells(@top_left[0], @top_left[1], @n_tbl)
    @ws_num.save()
    put_labels
    @ws_den.update_cells(@top_left[0], @top_left[1], @f_tbl)
    @ws_den.save()
  end

  def cell_by_cell
    puts 'cell_by_cell start.'
    ((@bound+1)..(@bound+10)).each{|m|
      (1..@bound).each{|n|
        puts "calc,  m:#{m}, n:#{n}"
        denom = (@r**n - @p**m).abs
        fact_str = denom.prime_division.to_s
        puts fact_str
        begin
          puts "writing m:#{m}, n:#{n}"
          @ws_num.update_cells(@top_left[0]+m, @top_left[1]+n, [[denom]])
          @ws_num.save()
          @ws_den.update_cells(@top_left[0]+m, @top_left[1]+n, [[fact_str]])
          @ws_den.save()
        rescue
          get_ws
          retry
        end
      }
    }
    (1..(@bound+10)).each{|m|
      ((@bound+1)..(@bound+10)).each{|n|
        denom = (@r**n - @p**m).abs
        fact_str = denom.prime_division.to_s
        begin
          puts "writing m:#{m}, n:#{n}"
          @ws_num.update_cells(@top_left[0]+m, @top_left[1]+n, [[denom]])
          @ws_num.save()
          @ws_den.update_cells(@top_left[0]+m, @top_left[1]+n, [[fact_str]])
          @ws_den.save()
        rescue
          get_ws
          retry
        end
      }
    }
  end  
end

if __FILE__ == $0
  qdt = QDenomTable.new 3
  qdt.make_table
  qdt.start_gdrive
  qdt.put_all
  qdt.cell_by_cell
end
