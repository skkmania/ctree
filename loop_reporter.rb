#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# loop_reporter.rb

require 'optparse'
require 'pathname'
dirname = Pathname(__FILE__).expand_path.dirname.to_s
require dirname + '/gen_loop_patterns.rb'
require dirname + '/pattern_to_exp.rb'

class LoopReporter
  def initialize p:3, len:3, pat:""
    @p = p
    @r = p - 1
    @q = [0] + (1..(@p-2)).to_a.reverse
    @len = len
    @pattern = pat
    @parser = Parser.new p:@p, pat:@pattern
    @patterns = Patterns.new(p:@p, len:@len).return_array
    @rep = []
    @rep_single = []
  end
  attr_accessor :p, :len, :pattern
  attr_reader :rep

  def report
    x_search_bound = $opts[:x_search_bound] || 100
    q_index_bound = $opts[:q_index_bound] || 100
    def_q = [0] + (1..(@p-2)).to_a.reverse
    @patterns.each{|p|
      pattern_single_q_flag = (p.chars.select{|c| c != "0" }.sort.uniq.size == 1)
      output_str = "\npattern : #{p}"
      if pattern_single_q_flag
        @rep_single.push output_str
      else
        @rep.push output_str
      end
      puts output_str
      (0..q_index_bound).each{|i|
        @q[1] = i*@r + def_q[1] 
        # print "\r q : [ 0, #{i}, - ]"
        (0..q_index_bound).each{|j|
          @q[2] = j*@r + def_q[2] 
          # print "\r q : [ 0, #{i}, #{j} ]"
          @parser.q = @q
          @parser.parse p
          cnt = 1
          while cnt < x_search_bound and !@parser.loop_check(cnt)
            # print "\r #{cnt}"
            cnt += 1
          end
          if cnt >= x_search_bound
            print "\r (#{i},#{j}) loop not found."
          else
            puts if $opts[:verbose]
            @pattern = p
            loopstr = q_to_s(pattern_to_loop(cnt))
            keta = q_index_bound.to_s.size
            output_str = "(#{sprintf("%#{keta}d",i)},#{sprintf("%#{keta}d",j)}):q#{q_to_s @q}:#{loopstr}" 
            if pattern_single_q_flag
              if i == 0 || j == 0 || i == q_index_bound || j == q_index_bound
                @rep_single.push output_str
              end
            else
              @rep.push output_str
            end
            puts output_str if $opts[:verbose]
          end
        }
      }
    }
    return @rep
  end

  def q_to_s ary
    keta = ary.max.to_s.size
    ret = ary.inject("["){|str, e|
      str = str + sprintf("%#{keta}d", e) + ","
      str
    }
    return ret[0..-2] + "]"
  end

  def pattern_to_loop x
    @pattern.chars.map(&:to_i).inject([x, []]){|ary, mov|
      now, ret = ary
      ret.push now
      div, mod = now.divmod @r
      now = (mov == 0 ? div : @p*now + @q[mod])
      [now, ret]
    }[1]
  end 

  def write_file fn
    open(fn,'w'){|f|
      @rep_single.each{|line| f.puts line }
      @rep.each{|line| f.puts line }
    }
  end
end

if __FILE__ == $0
  $opts = {}
  ARGV.options do |op|
    op.banner = "ruby #$0 [options] [args]"
    op.on("-v", "--verbose", "print process to stdout"){|x| $opts[:verbose] = x }
    op.on("-o string", "--o_file", "file name for output"){|x| $opts[:o_file] = x }
    op.on("-x integer", "--x_search_bound", "starting number of searching loop. from 0 to x_search_bound. default value is 100"){|x| $opts[:x_search_bound] = x.to_i }
    op.on("-X integers", "--x_search_range", "range of starting numbers, searching loop start from each number in this range"){|x| $opts[:x_search_range] = x.split(',').map(&:to_i) }
    op.on("-q integer", "--q_index_bound", "range of q_index. from 0 to q_index_bound. default value is 100"){|x| $opts[:q_index_bound] = x.to_i }
    op.on("-p string", "--pattern", "specify pattern you want"){|x| $opts[:pattern] = x }
    op.on("-i integers", "--index_start", "q index start from here"){|x| $opts[:index_start] = x.split(',').map(&:to_i) }
    op.parse!
  end
  o_filename = $opts[:o_file]

  lr = LoopReporter.new(p:ARGV[0].to_i, len:ARGV[1].to_i)
  lr.report
  lr.write_file o_filename if o_filename
end

