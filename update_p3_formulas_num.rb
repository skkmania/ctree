#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#   update_p3_formulas_num.rb
#   mysqlのp3_loops DB table のうち
#    p3_formulas
#   データ num denom をupdateする.
#   動作：
#     p3_formulas_.. tableを読み
#     p3_formulaからnum, denomを算出する
#     それぞれをupdateする
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
    @f_tab_name = "p3_formulas" + post_fix
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

  def update_db
    q = "update #{@f_tab_name} set num = cast(substring(p3_formula,1,locate('*',p3_formula)-1) as signed);"
    @session.query q
    q = "update #{@f_tab_name} set denom = cast(substring(p3_formula,locate('/',p3_formula)+1) as signed);"
    @session.query q
  end

end

if __FILE__ == $0
  post_fix = ARGV[0]
  rg = Register.new post_fix
  rg.start_session
  rg.update_db
end

