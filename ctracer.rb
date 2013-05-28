#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# ctracer.rb

class CTStandardError < StandardError; end
class CTArgumentError < ArgumentError; end
class CTDirectionError < ArgumentError; end
class CTValidateQError < ArgumentError; end

class CTracer
  def initialize(p: nil, now: nil, q: nil)
    @now = (now ? now : 1)
    @p = (p ? p : 3)
    @r = p-1
    @q = (q ? q : [0] + (1..@r).to_a.reverse)
    validate_q
  end
  attr_accessor :q, :now
  attr_reader :p,:r

  def validate_q
    raise CTValidateQError, "#{@q.to_s} does not have #{@r} elements" if @q.length != @r
    std_q = [0] + (1..(@r-1)).to_a.reverse
    wrong_pairs = (std_q.zip(@q))[1..-1].reject{|p| (p[1] == p[0]) or ((p[1]-p[0]) % @r == 0) }
    if wrong_pairs.size > 0
      raise CTValidateQError, "#{@q.to_s} have wrong elements : #{wrong_pairs.map{|pair| pair[1] }.to_s}"
    end
  end  

  def modify_q index, value
    @q[index] = value
  end

  def type
    @now % @p
  end

  def ups
    ret = { 0 => @now * @r }
    (1..(@r-1)).each{|direction|
      div, mod = (@now - @q[direction]).divmod @p
      #raise CTStandardError,"#{@now} - @q[#{direction}]/#{@p} became 0." if div == 0
      next if div == 0
      if mod == 0 and ((div * @p) + @q[div % @r]) == @now
        ret[direction] = div
      end
    }
    return ret
  end

  def branches
    (1..(@r-1)).to_a.select{|direction|
      div, mod = (@now - @q[direction]).divmod @p
      mod == 0 and ((div * @p) + @q[div % @r]) == @now
    }.size + 1
    # + 1 because up branch for direction-0 always exists  
  end

  def up
    return (lambda{|direction|
      return @now = @now * @r if direction == 0
      div, mod = (@now - @q[direction]).divmod @p
      raise CTStandardError if div == 0
      if mod == 0 and ((div * @p) + @q[div % @r]) == @now
        @now = div
      else
        raise CTDirectionError, "can not go to #{direction}"
      end
    })
  end

  # x まで上がれるか?
  # 上がれるなら、上がってself
  # x,に着くまえにpathをたどれなくなるときは元の位置のままfalse
  def up_to? x, path
    dummy = CTracer.new @p, @now
    if dummy.up_tracable? path and dummy.trace.include? x
      @now = x
      @trace = dummy.trace
      return self
    else
      return false
    end
  end

  # x まで降りられるか?
  # 降りられるなら、降りてtrue
  # loopにおちてしまいxまでたどりつけないときは元の位置のままfalse
  def down_to? x
    dummy = CTracer.new @p, @now
    dummy.down_to_loop
    if dummy.trace.include? x  or  dummy.loop_ary.include? x
      @now = x
      return self
    else
      return false
    end
  end

  # std loopは除く
  def down_to_loop start=nil
    if start
      @now = start
    end
    @loop_ary = [@now]
    @shadow = @now
    until @in_loop
      shadow_down
      @loop_ary.push @shadow
      shadow_down
      @loop_ary.push @shadow
      if @shadow == 1
        return nil
      end
      @loop_ary.shift
      @now = @loop_ary[0]
      @trace.push @now
      @in_loop = (@shadow == @now)
    end
    @loop_ary = @loop_ary[0..(@loop_ary[1..-1].index @loop_ary[0])]
    @lp.size = @loop_ary.size
    @lp.min = @loop_ary.min
    @lp.max = @loop_ary.max
  end

  def down
    div, mod = @now.divmod @r
    @now = (mod == 0 ? div : @p * @now + @q[mod] )
  end
end

if __FILE__ == $0
  t = CTracer.new(p:4, now:63, q:[0, 2, 1])
  puts t.now.to_s
  t.down
  t.up.call(0)
  puts t.now.to_s
end
