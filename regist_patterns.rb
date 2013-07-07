#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#   regist_patterns.rb
#   mysqlのp3_loops DB table のうち
#   patterns, p3_formulas, formula_texs
#   のデータを登録する
#   patternにもとづいてmaximaのマクロでデータを生成する
#   このスクリプトは使い捨て
#   
require 'mysql2'
require 'net/ssh'
require 'net/scp'

class Register
  def initialize
    @unit = 50
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

  def get_next_unit_pid_and_pattern index
    q = "select pid, pattern from patterns limit #{index*@unit}, #@unit"
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
    (63..200).to_a.each do |idx|
      get_next_unit_pid_and_pattern(idx).each{|h|
        run_maxima h['pid'], h['pattern']
      }
      system "scp ml2013:/home/skkmania/workspace/ctree/tmp.out ."
      cmd = %|(cd workspace/ctree;mv tmp.out data/p3_patterns/source_#{idx}.txt)|
      exec_ssh 'ml2013', 'skkmania', cmd
      update_db
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
      upd_expr = "update  patterns SET expression = '#{expr}', qformula = '#{q_formula}' WHERE pid = #{pid}"
      @session.query upd_expr
      ins_q3f = "insert into  p3_formulas (pid, p3_formula) values (#{pid}, '#{p3_formula}') on duplicate key update p3_formula = '#{p3_formula}'"
      @session.query ins_q3f
      ins_texs = "insert into  formula_texs (pid, formula_tex) values (#{pid}, '#{tex}') on duplicate key update formula_tex = '#{tex}'"
      #upd_texs = "update  formula_texs SET formula_tex = '#{tex}' WHERE pid = #{pid}"
      @session.query ins_texs
    }
  end
=begin
      if ret.size == 0
        ins_pat = "insert into patterns (pid, pattern) values (#{pid}, '#{pattern}')"
        @session.query ins_pat
      end
=end

end

if __FILE__ == $0
  rg = Register.new
  rg.start_session
  #rg.run_maxima ARGV[0], ARGV[1]
  rg.maxima_session
  #rg.update_db
end

