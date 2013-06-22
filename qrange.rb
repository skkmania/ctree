#!/usr/bin/env ruby
# -*- coding:utf-8 -*-
# qrange.rb
#
#    ctreeの探査においてp,qを動かすprogramがよく登場する
#    普通に(0..100).each{|q1|
#             (0..100).each{|q2|
#    とやっていたのでは、pを動かそうと思うとqの次元が変わるのでソースコードを
#    書き換えることになってしまう。
#    そこで、qの次元が変わっても、次のq,次のq,という呼出を続けるだけで
#    調べたい範囲のqを全部調べることができるようにしたい
#
#    そこで、
#    QRange
#    というenumeratorをつくる
#    使用イメージ
#      qr = QRange.new 4, { :q_index_ranges => {2=>[2,3,4]} }
#      [0..9]x[2,3,4] を走査する      
#      つまり、[0,0,2]から始まり、next_q_indexを呼べば[0,0,3],再度呼べば[0,0,4],
#      再度呼べば[0,1,2]とくりあがり、最後には[0,9,4]で終わる.
#      このように、option指定により走査範囲を指定できる.
#      defaultでは[0..9]x[0..9]を走査する.
#
#
# 言葉解説
#    Q とはctree (p, q, root, step)におけるqのモデルであり、配列であらわされる
#    p があたえられれば、その長さ(p-1)が決まる
#      例:  p = 4 のとき、q = [0, 2, 1]
#    qの配列のindexはctreeにおいてnodeをr(=p-1)で除したときの剰余を意味する
#      例:  q = [0, 2, 1] = [q0, q1, q2] と呼ぶとすると
#    node % r が 1ならば p * node + q1 という操作をすることになる
#
#    default_q とは
#
#    q_index とは
#
#    q_index_ranges とは
#

class Array
  # 配列の全要素を循環的に参照するためのmethod
  # 動作例のイメージ
  #   [0,1,2,3,4,5]
  #   において、3の次は4, 4の次は5, 5の次は0, 0の次は1,...を返す
  #   次とは、単にindexの順番による。(末尾の次は先頭)
  #   つまり、[0,1,4,3,2,5].next_to 3  #=> 2
  #           [0,1,4,3,2,5].next_to 5  #=> 0
  #   という具合。
  # ただし、実際の動作では単に要素を返すのではなく、
  # 返り値は次のとおり。
  #   nil : レシーバが空配列のとき。      [].next_to 3 #=> nil
  #   nil : 存在しない要素を指定したとき。[1,2,3].next_to 5 #=> nil
  #   配列 [boolean, 要素] :
  #     boolean : true   先頭に戻ったとき
  #               false  その他
  #       (くりあがり演算の補助が目的)
  #     要素    : 指定した要素の次の要素
  #
  def next_to e
    return nil if size == 0
    pos = index e
    return nil unless pos
    return [true, at(0)] if pos == size - 1
    [false, at(pos + 1)]
  end
end

class QRange
  include Enumerable
  def initialize(p, option={})
    @p = p.to_i
    @r = @p - 1
    @q_ranges = (option[:q_ranges] ? option[:q_ranges] : {} )
    @q_index_ranges = default_q_index_ranges
    @q_index_ranges.merge!(option[:q_index_ranges]) if option[:q_index_ranges]
    @q_count = 0
    @next_q_bound = 10**(@p-2)
    @pass_list = []
  end
  attr_accessor :p, :q, :q_count, :next_q_bound, :q_ranges, :q_index, :q_index_ranges, :pass_list

  def each
    rewind
    yield @q_index
    while next_q_index do
      yield @q_index
    end
  end
  alias each_index each

  def each_with_count
    rewind
    yield @q_index, @q_count
    while next_q_index do
      @q_count += 1
      yield @q_index, @q_count
    end
  end

  def each_q
    rewind
    yield q_index_to_q
    while next_q_index do
      yield q_index_to_q
    end
  end

  def first
    @q_count = 0
    @q_index = @q_index_ranges.values.map(&:first) 
  end
  alias rewind first 

  def last
    @q_count = @q_index_ranges.values.inject(1){|sz, ar| sz *= ar.size; sz }
    @q_index = @q_index_ranges.values.map(&:last) 
  end

  def size
    @q_index_ranges.values.inject(1){|sz, ar| sz *= ar.size; sz }
  end

  def default_q
    [0] + (1..(@p-2)).to_a.reverse
  end

  def q_to_q_index
    @q_index = (@q.zip(default_q)).map{|a| (a[0] - a[1])/@r }
  end

  def q_index_to_q
    @q = (@q_index.zip(default_q)).map{|a| a[1] + @r*a[0] }
  end

  def set_q_index_ranges str
    @q_index_ranges.update eval(str)
    (1..(@p-2)).each{|n| @q_index[n] = @q_index_ranges[n][0] }
  end 

  def default_q_index_ranges
    ret = { 0 => [0] }
    (1..(@p-2)).each{|n| ret[n] = (0..9).to_a }
    ret
  end 

  def set_default p
    @p = p
    @q = default_q
    @q_index = q_to_q_index
    @q_index_ranges = default_q_index_ranges
    @q_count = 0
    @next_q_bound = 10**(@p-2)
  end

  def count_to_q
    ar = [0] + sprintf("%0#{@p-2}d",@q_count).split('').map(&:to_i)
    def_q = default_q 
    (1..(@p-2)).to_a.each{|i|
      @q[i] = (@p - 1)*ar[i] + def_q[i] 
    }
  end

  def next_q
    return nil if @q_count == @next_q_bound
    @q_count +=1
    while @pass_list.include? @q_count
      @pass_list.delete @q_count
      @q_count +=1
    end
    count_to_q
  end
  alias succ next_q

  def count_to_q_index
  end

  # next_q_index
  #   現在の@q_indexをひとつ進ませる
  # 返り値
  #   nil : rangeの最後まで到達したとき
  #   true : その他、順調なとき
  def next_q_index
    cnt = @p - 2
#puts "cnt: #{cnt}, q_index_ranges: #{@q_index_ranges.inspect}"
    # 一番外側(最小)のケタをひとつ進める
    tmp = @q_index_ranges[cnt].next_to @q_index[cnt]
#puts "tmp: #{tmp.inspect}"
    @q_index[cnt] = tmp[1]
#puts "q_index: #{@q_index.inspect}"
    while tmp[0] and cnt > 0
      # ここに来るのは「くりあがり」が発生したとき
      cnt -= 1
      return nil if cnt == 0 # 最後までくりあがりきったことになるのでnilで終了を示す
      # 普通は、くりあがったケタもひとつ進めることになる
      tmp = @q_index_ranges[cnt].next_to @q_index[cnt]
      @q_index[cnt] = tmp[1]
    end
    true
  end

end

if __FILE__ == $0
  opts = {}
  ARGV.options do |op|
    op.banner = "ruby #$0 [options] [args]"
    # op.separator "Ruby-like options:"
    op.on("-p integer", "--p_start", "start of p range"){|x| opts[:p_start] = x.to_i }
    op.on("-P integer", "--p_end", "end of p range"){|x| opts[:p_end] = x.to_i }
    op.on("-o string", "--o_file", "file name for output"){|x| opts[:o_file] = x }
    op.on("-s integer", "--steps", "number of steps down from target"){|x| opts[:steps] = x.to_i }
    op.on("-t integer", "--target", "target integer"){|x| opts[:target] = x.to_i }
    op.on("-l integer", "--limit_size", "output limit size"){|x| opts[:limit_size] = x.to_i }
    op.on("-q hash_literal", "--q_index_ranges", "q_index_ranges"){|x| opts[:q_index_ranges] = x }
    op.parse!
  end
  o_filename = opts[:o_file]
  (p_start..p_end).each{|p|
    to.set_default p
    to.set_q_index_ranges opts[:q_index_ranges] if opts[:q_index_ranges] 
    to.of = open("#{o_filename}_t#{tgt.size}_p#{p}.csv",'w+') if ARGV[0] != 'google'
    while to.next_q_index do
      to.q = to.q_index_to_q
      to.go_steps down_steps
      # to.make_pass_list
      to.output o_filename
      # print "\r processing #{to.q_count}" # if to.q_count % 100 == 0
    end
  }
  puts
end
