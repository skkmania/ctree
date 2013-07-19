#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#   update_pat_num.rb
#   mysqlのp3_loops DB table のうち
#    pat_num_..
#   を作成し、
#   データ num_0, num_1 をinsertする.
#   動作：
#     patterns_.. tableを読み
#     patternから num_0, num_1を算出する
#   Usage:
#     ruby update_pat_num post_fix
#     post_fix : string : e.g. _30   _31  _32_1  _32_2 .....
#   
require 'mysql2'

class Register
  def initialize post_fix
    # この数字は作業のまとめ単位を意味する
    # @unit=50ならば
    # 50個ずつpatternsからpatternを読み、
    # ml2013のmaximaで50個ぶんの計算結果をfile(tmp.out)に出力し
    # それをこのhostにコピーし、読みこみ、DBへ登録する
    @post_fix = post_fix
    @tab_name = "pat_num" + post_fix
    @p_tab_name = "patterns" + post_fix
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

  def mk_table
    q = "drop table if exists #{@tab_name}"
    @session.query q
    q = "CREATE TABLE #{@tab_name}(
         pid  int not null primary key,
         num_0 int not null,
         num_1 int not null
         );" 
    @session.query(q)

  end

  def insert_data
    q = "INSERT INTO #{@tab_name}
          SELECT pid,
                 length(replace(pattern,\"1\",\"\")) as num_0,
                 length(replace(pattern,\"0\",\"\")) as num_1
            FROM #{@p_tab_name};"
    @session.query(q)
  end

end

if __FILE__ == $0
  post_fix = ARGV[0]
  rg = Register.new post_fix
  rg.start_session
  rg.mk_table
  rg.insert_data
end

