#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#   create_patterns_table.rb
#     gen_patterns_with_rotate_check_for.rbにより作成したtext fileを読み
#     patterns_{len}_{n}
#     tableをDB p3_loops内に作成する
#
#   このスクリプトを動かすことは少ないはず。
#   なので、手作業に依存する部分をそのまま残している。
#   具体的には
#   len_32_20_12.txtなどのpatternを記述したファイルを
#   いくつづつまとめて、いくつのテーブルをつくるのか、を
#   対象の大きさによりその都度自分で決定し,
#   メインの呼出のところに
#   記述してから、このスクリプトを動かすこととする。
#   
require 'mysql2'

class Register
  def initialize len, post_fix, pattern_files
    # この数字は作業のまとめ単位を意味する
    # @unit=50ならば
    # 50個ずつpatternsからpatternを読み、
    # ml2013のmaximaで50個ぶんの計算結果をfile(tmp.out)に出力し
    # それをこのhostにコピーし、読みこみ、DBへ登録する
    @len = len
    @pattern_files = pattern_files
    @p_tab_name = "patterns" + post_fix
    @f_tab_name = "p3_formulas" + post_fix
    @t_tab_name = "formula_texs" + post_fix
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

  def create_patterns_table
    q = "drop table if exists #{@p_tab_name};"
    @session.query(q)
    q = "CREATE TABLE #{@p_tab_name}(
         pid  int auto_increment not null primary key,
         pattern char(#{@len}) not null,
         expression varchar(#{@len*20}) not null,
         qformula varchar(#{@len*20}) not null
         ) engine=InnoDB;"
    @session.query(q)
    q = "create index #{@p_tab_name}_idx on #{@p_tab_name}(pattern);"
    @session.query(q)
  end

  def create_formulas_table
    q = "drop table if exists #{@f_tab_name};"
    @session.query(q)
    q = "CREATE TABLE #{@f_tab_name}(
         pid  int not null primary key,
         p3_formula varchar(#{@len*5}) not null,
         num  int not null,
         denom  int not null,
         foreign key(pid) references #{@p_tab_name}(pid)
       ) engine=InnoDB;"
    @session.query(q)
  end

  def create_formula_texs_table
    q = "drop table if exists #{@t_tab_name};"
    @session.query(q)
    q = "CREATE TABLE #{@t_tab_name}(
         pid  int not null primary key,
         formula_tex varchar(#{@len*30}) not null,
         foreign key(pid) references #{@p_tab_name}(pid)
       ) engine=InnoDB;"
    @session.query(q)
  end

  def load_file
    @pattern_files.each{|file_name|
      q = "load data infile '#{file_name}' into table #{@p_tab_name} (pattern);"
      @session.query(q)
    }
  end

end

if __FILE__ == $0
  len = 30
  post_fix = '_30'
  pattern_files = ['/home/skkmania/workspace/ctree/data/p3_patterns/len_30.txt']
  rg = Register.new len, post_fix, pattern_files
  rg.start_session
  rg.create_patterns_table
  rg.create_formulas_table
  rg.create_formula_texs_table
  rg.load_file
end

