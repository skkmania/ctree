#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#   regist_patterns.rb
#   mysqlのp3_loops DB table のうち
#   patterns, p3_formulas, formula_texs
#   にデータを登録する.
#   patternにもとづいてmaximaのマクロでデータを生成する.
#   このスクリプトは使い捨て.
#   (というか、patterns tableにあらたにpatternが追加されたときのみ使う意味がある.
#   追加ぶんに対して一度使ったらそれで終わり、という意味での「使い捨て」)
#     2013.7.12現在、@unit( = 50) * 200 のpatternを処理済み
#   動作：
#     patterns tableを読み
#     patternからexpression, qformula、p3_formula, formula_texを算出する
#        (この算出にはml2013のsage -maximaを使う。)
#     それぞれを該当するtableへ登録する
#   
require 'mysql2'
require 'net/ssh'
require 'net/scp'

class Register
  def initialize post_fix
    # この数字は作業のまとめ単位を意味する
    # @unit=50ならば
    # 50個ずつpatternsからpatternを読み、
    # ml2013のmaximaで50個ぶんの計算結果をfile(tmp.out)に出力し
    # それをこのhostにコピーし、読みこみ、DBへ登録する
    @unit = 50
    @post_fix = post_fix
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

  def get_count_of_patterns
    q = "select count(*) as cnt from #{@p_tab_name}"
    @session.query(q).to_a[0]['cnt']
  end

  def get_next_unit_pid_and_pattern
    q = "select pid, pattern from #{@p_tab_name} where expression = '' order by pid limit #{@unit}"
    @session.query(q).to_a
  end

  def run_maxima pid, pattern
    cmd = %|(cd workspace/ctree;sage -maxima -q --batch-string="pid:#{pid};pattern:\\"#{pattern}\\";batchload(\\"pat2db.mac\\");")|
    res = exec_ssh 'ml2013', 'skkmania', cmd
    unless res
      puts "no answer from ml2013"
      return
    end
    if /Error/ =~ res
      puts "error at #{pid}, #{pattern}"
    else
      puts "succeeded. : #{res.split("\n").select{|l| /pid|pattern/ =~ l }.join(" : ")}"
    end
  end

  def exec_ssh(hostname, username, cmd)
    ret = nil
    begin
      Net::SSH.start(hostname, username) do |ssh|
        ret = ssh.exec! cmd
      end
      ret
    rescue
    end
  end
    
  def maxima_session
    system "ssh ml2013 rm /home/skkmania/workspace/ctree/tmp.out"
    system "ssh ml2013 mkdir /home/skkmania/workspace/ctree/data/#{@post_fix}"
    ar = get_next_unit_pid_and_pattern
    while ar.size > 0 do
      ar.each{|h|
        run_maxima h['pid'], h['pattern']
      }
      pids = ar.map{|h| h['pid'].to_i }
      idx = "#{pids.min}_#{pids.max}"
      system "scp ml2013:/home/skkmania/workspace/ctree/tmp.out ."
      cmd = %|(cd workspace/ctree;mv tmp.out data/p3_patterns/#{@post_fix}/source_#{idx}.txt)|
      exec_ssh 'ml2013', 'skkmania', cmd
      update_db
      ar = get_next_unit_pid_and_pattern
    end
    puts " *** \n end maxima session \n ***"
  end

  def update_db
    open('tmp.out').readlines.each_slice(5){|lines|
      pid = lines[0].chomp
      expr = lines[1].chomp
      q_formula = lines[2].chomp
      p3_formula = lines[3].chomp
      tex = lines[4].chomp.gsub('\\','\\\\\\\\')
      upd_expr = "update  #{@p_tab_name} SET expression = '#{expr}', qformula = '#{q_formula}' WHERE pid = #{pid}"
      @session.query upd_expr
      ins_q3f = "insert into  #{@f_tab_name} (pid, p3_formula) values (#{pid}, '#{p3_formula}') on duplicate key update p3_formula = '#{p3_formula}'"
      @session.query ins_q3f
      ins_texs = "insert into  #{@t_tab_name} (pid, formula_tex) values (#{pid}, '#{tex}') on duplicate key update formula_tex = '#{tex}'"
      @session.query ins_texs
    }
  end

end

if __FILE__ == $0
  post_fix = ARGV[0]
  rg = Register.new post_fix
  rg.start_session
  rg.maxima_session
end

