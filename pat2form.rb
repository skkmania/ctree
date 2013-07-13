#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#   pat2form.rb
#   Usage: pat2form.rb pattern_string
#   given a pattern string( e.g. 101001000 ), returns formula  
#   
require 'net/ssh'
require 'net/scp'

class Register
  def initialize
  end

  def run_maxima pattern
    cmd = %|(cd workspace/ctree;sage -maxima -q --batch-string="pid:0;pattern:\\"#{pattern}\\";batchload(\\"pat2db.mac\\");")|
    res = exec_ssh 'ml2013', 'skkmania', cmd
    unless res
      puts "no answer from ml2013"
      return
    end
    if /Error/ =~ res
      puts "error at #{pattern}"
    else
      puts "succeeded. : #{res.split("\n").select{|l| /pattern/ =~ l }.join(" : ")}"
      system "scp ml2013:/home/skkmania/workspace/ctree/tmp.out ."
      system "cat tmp.out"
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
    
end

if __FILE__ == $0
  rg = Register.new
  rg.run_maxima ARGV[0]
end

