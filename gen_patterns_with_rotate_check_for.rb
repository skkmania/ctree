#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# gen_patterns_with_rotate_check_for.rb
#   p = 3 を前提。
#   #0, #1を指定し、ありうる全てのloopのpatternを出力する
#  Usage:
#    gen_patterns_with_rotate_check_for.rb #0 #1
#
#  経緯：
#  old/gen_patterns_for.rb では一度素材をHashに貯めたあとに一気にrotate duplication checkをかけていた
#  それではpattern lengthが大きくなるとメモリ負荷と処理時間がひどくなるので
#  本scriptでは、一度、素材をfileに書き出し、それをmysqlのtableに格納する
#  そのtableにindexを作成し検索性能を稼いでから
#  duplication check を実行し、その結果を最終結果としてあらためてファイルに出力する
#
require 'mysql2'

class Patterns
  def initialize n0, n1
    @p = 3
    @r = 2
    @n0 = n0
    @n1 = n1
    @len = n0 + n1
    @tmp_file_name = "/home/skkmania/workspace/ctree/data/p3_patterns/tmp_len_#{n0+n1}_#{n0}_#{n1}.txt"
    @out_file_name = "/home/skkmania/workspace/ctree/data/p3_patterns/len_#{n0+n1}_#{n0}_#{n1}.txt"
  end
  attr_accessor :len
  attr_reader :base_hash

  #
  #  まずpatternの素材をつくっておく。
  #    @len - 1 
  #  後でここからpatternではないものを取り除いて最終報告とする
  def generate_base
    open(@tmp_file_name,'w'){|f|
      (1..@n0-1).to_a.combination(@n1-1).each{|ar|
        prev = 0
        pat = ar.inject("10"){|mem,e| mem = mem + "0"*(e - prev - 1) + "10"; prev = e; mem }
        pat = pat + "0"*(@len - pat.size) 
        next if check_if_cycle_occurs pat
        f.puts pat
      }
    }
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

  def start_session
    lines = open('./.mysql.conf').readlines.map{|l| l.chomp }
    opt = {
      :host => 'localhost',
      :username => lines[0].split(':')[1],
      :password => lines[1].split(':')[1],
      :database => lines[2].split(':')[1],
    }
    @session = Mysql2::Client.new opt
  end
  #
  # file -> tmp_pat_store@DB
  #
  def regist_patterns_on_db
    # create table
    q = "drop table if exists tmp_pat_store;"
    @session.query(q)
    q = "create table tmp_pat_store (pat char(#{@len}), primary key(pat));"
    @session.query(q)
    q = "load data infile '#{@tmp_file_name}' into table tmp_pat_store;"
    @session.query(q)
  end

  #
  # loopなので、素材の2つが循環して同じならひとつだけ残せばよい
  #
  def rotate_duplication_check
    q = "select pat from tmp_pat_store limit 1;"
    ar = @session.query(q).to_a
    while ar.size > 0
      pat = ar[0]['pat']
      open(@out_file_name,'a'){|f| f.puts pat }
      rotates = make_rotation pat
      rotates.each{|p|
        q = "delete from tmp_pat_store where pat = '#{p}';"
        @session.query(q)
      }
      q = "select pat from tmp_pat_store limit 1;"
      ar = @session.query(q).to_a
    end
  end

  def make_rotation pat
    ret = []
    cnt = 1
    rot = pat.split('').rotate.join
    ret.push rot
    while cnt < pat.size do
      cnt+=1
      rot = rot.split('').rotate.join
      ret.push rot
    end
    ret
  end  
end

if __FILE__ == $0
  n0 = ARGV[0].to_i
  n1 = ARGV[1].to_i
  if 2**n0 - 3**n1 < 0
    puts "aborting: 2**#{n0} - 3**#{n1} must be positive."
    exit
  end
  ps = Patterns.new n0, n1
  ps.generate_base
  ps.start_session
  ps.regist_patterns_on_db
  ps.rotate_duplication_check
end

