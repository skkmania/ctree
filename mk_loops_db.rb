#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#   mk_loops_db.rb
#   data/p3_loops, data/p3_formulas, data/p3_patterns, data/p3_solves
#   にあるものをmysqlのp3_loops DBに登録する
#   このスクリプトは使い捨て
#   
require 'mysql2'

class Register
  def initialize fname
    @fname = fname
  end
  attr_accessor :fname

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

  def get_pid pat
    q = "select pid from patterns where pattern = '#{pat}'";
    res = @session.query(q).to_a[0]
    res ? res['pid'] : nil
  end

  def get_max_id_of_loop
    q = 'select max(id) from loops';
    @session.query(q).to_a[0].values[0]
  end

  def get_max_id_of_pattern
    q = 'select max(pid) from patterns';
    @session.query(q).to_a[0].values[0]
  end

  def pattern_file_to_db
    pid = get_max_id_of_pattern + 1
    open(@fname).each_line{|line|
      pattern = line.chomp.split(',')[-1]
      find_pat = "select pattern from patterns where pattern = '#{pattern}'"
      ret = @session.query find_pat
      if ret.size == 0
        ins_pat = "insert into patterns (pid, pattern) values (#{pid}, '#{pattern}')"
        @session.query ins_pat
        puts "#{pid}, #{pattern} was inserted."
        pid += 1
      end
    }
  end

  def process
    cnt = get_max_id_of_loop + 1
    pid = get_max_id_of_pattern + 1
    open(@fname).readlines.each_slice(10){|lines|
      # q = lines[1].chomp.split(': ')[1]
      # qid = lines[2].chomp.split(': ')[1]
      # size = lines[3].chomp.split(': ')[1]
      # num_0 = lines[4].chomp.split(': ')[1]
      # num_1 = lines[5].chomp.split(': ')[1]
      loop_str = lines[8].chomp.split(': ')[1]
      pattern = lines[9].chomp.split(': ')[1]
      ins_loop = "insert into loops (id, loop_str) values (#{cnt}, '#{loop_str}')"
      @session.query ins_loop
      find_pat = "select pattern from patterns where pattern = '#{pattern}'"
      ret = @session.query find_pat
      if ret.size == 0
        ins_pat = "insert into patterns (pid, pattern) values (#{pid}, '#{pattern}')"
        @session.query ins_pat
        pid += 1
      end
      cnt += 1
    }
  end
=begin
      ins_qid = "insert into qids (id, qid, q) values (#{cnt}, #{qid}, #{q})"
      @session.query ins_qid
      ins_sid = "insert into sids (id, sid, size) values (#{cnt}, #{sid}, #{size})"
      @session.query ins_sid
      ins_nid = "insert into nids (id, nid, num_0, num_1) values (#{cnt}, #{nid}, #{num_0}, #{num_1})"
      @session.query ins_nid
      ins_qformula = "insert into qformulas (id, qformula) values (#{cnt}, #{get_qformula pattern})"
      @session.query ins_qformula
      ins_expression = "insert into expressions (id, expression) values (#{cnt}, #{get_expression pattern})"
      @session.query ins_expression
=end

  def get_expression
    
  end

  def compare_length_of_patterns len
    ans = @session.query("select pattern from patterns where length(pattern) = #{len}").to_a
    ans = ans.map{|h| h['pattern'] }
    open("data/p3_patterns/len_#{len}.csv").each_line{|line|
      pat = line.chomp.split(',')[-1]
      cnt = pat.size
      while !(ans.include? pat) and cnt > 0
        pat = pat.chars.rotate.join
        cnt -= 1
      end
      puts pat if cnt == 0
    }
  end

  def put_formulas
    open(@fname).readlines.each_slice(9){|lines|
      pat = lines[0].chomp
      exp = lines[1].chomp.split('== ')[1]
      form = lines[4].chomp.split('== ')[1]
      p3form = lines[7].chomp.sub('==','=')
      upd = "update patterns set expression = '#{exp}', qformula = '#{form}'  where pattern = '#{pat}'"
      @session.query upd

      pid = get_pid pat
      if pid
        ins_p3 = "insert into p3_formulas (pid, p3_formula) values (#{pid}, '#{p3form}')"
        @session.query ins_p3
      end
    }
  end

end

if __FILE__ == $0
  fname = ARGV[0]
  rg = Register.new fname
  rg.start_session
  rg.pattern_file_to_db
  #rg.process
  #rg.put_formulas
end

