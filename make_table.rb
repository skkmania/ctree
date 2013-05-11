#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
#
require 'fileutils'
require 'logger'
require "google_drive"

class Tracer
  def initialize p
    @p = p
    @r = p-1
    @in_loop = false
    @loop_ary = []
  end
  attr_reader :loop_ary

  def down_to_root start=nil
    @now = start if start
    @shadow = @now
    until @in_loop
      down
      shadow_down
      shadow_down
      @in_loop = (@shadow == @now)
      #print "#{@now.to_s}  "
      #print "#{@now.to_s}  (#{@shadow.to_s})  "
    end
    sentinel = @now
    @loop_ary.push @now
    down
    while sentinel != @now
      @loop_ary.push @now
      down
    end
    puts "loop size: #{@loop_ary.size.to_s}"
    puts "loop min: #{@loop_ary.min.to_s}"
    puts "loop max: #{@loop_ary.max.to_s}"
    puts "loop: #{@loop_ary.join(',')}"
    return get_steps_to_loop start
  end

  def get_steps_to_loop start
    @now = start
    steps = 0
    until @loop_ary[0] == @now
      down
      steps += 1
    end
    puts "steps from #{start.to_s} to loop : #{steps.to_s}"
    if @loop_ary.include? 1
      return [steps, steps + @loop_ary.index(1)]
    else
      return [steps, nil]
    end
  end

  def down step=nil
    div, mod = @now.divmod @r
    if mod == 0
      @now = div
    else
      @now = @p * @now + (@r - mod)
    end
  end

  def shadow_down step=nil
    div, mod = @shadow.divmod @r
    if mod == 0
      @shadow = div
    else
      @shadow = @p * @shadow + (@r - mod)
    end
  end

  def up step=nil
    @now 
  end
end

def make_table
  session = GoogleDrive.login("skkmania@gmail.com", "wajiwaji2009")
# https://docs.google.com/spreadsheet/ccc?key=0AtsWWiWPzmSbdGR4YU1sQjgtTmdkU29Pc3BqcEpUYXc#gid=0
  ws = session.spreadsheet_by_key("0AtsWWiWPzmSbdGR4YU1sQjgtTmdkU29Pc3BqcEpUYXc").worksheets[0]

  (3..3000).each{|p|
    t = Tracer.new p
    ds = t.down_to_root 12345678901234567890
    last_row = ws.num_rows + 1
    ws[last_row, 1] = p
    ws[last_row, 2] = ds[0]
    ws[last_row, 3] = ds[1] if ds[1]
    ws[last_row, 4] = t.loop_ary.size
    ws[last_row, 5] = t.loop_ary.min
    ws[last_row, 6] = t.loop_ary.max
    ws.save()
  }
end

if __FILE__ == $0
# =begin
  t = Tracer.new ARGV[0].to_i
  t.down_to_root ARGV[1].to_i
# =end
#  make_table
end
