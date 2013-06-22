# k = m*p + n*q の一般解を求める
# d,p,qを与えると、d以下の、kを列挙する
def ippan1 d,p,q
  (1..d).each{|k|
    di,mo = k.divmod p
    if mo == 0
      print "#{k} "
      next
    end
    (0..di).each{|m|
      r = k - m*p
      if r%q == 0
        print "#{k} "
        break
      end
    }
  }
  puts
end

ippan1 30,3,7

# d,p,qを与えると、d以下の、kとともに
# そのときの、(m,n)も出力する。
# ただし、これはkが重複すると(m,n)を捨てる
# 結果になっている
def ippan2 d,p,q
  (1..d).each{|k|
    di,mo = k.divmod p
    if mo == 0
      print "#{k}:(#{di},0) "
      next
    end
    (0..di).each{|m|
      r = k - m*p
      di2, mo2 = r.divmod q
      if mo2 == 0
        print "#{k}:(#{m},#{di2}) "
        break
      end
    }
  }
  puts
end

ippan2 30,3,7

# k = m*p + n*q
# d,p,qを与えると、d以下の、kと
# kを成立させる[m,n]の配列のhashを返す。
# { k => [m,n], .... }
# ただし、これはkが重複すると(m,n)を捨てる
# 結果になっているので完全ではない
#
def ippan3 d,p,q
  ret = {}
  (1..d).each{|k|
    di,mo = k.divmod p
    if mo == 0
      ret[k] = [di,0]
      next
    end
    (0..di).each{|m|
      r = k - m*p
      di2, mo2 = r.divmod q
      if mo2 == 0
        ret[k] = [m,di2]
        break
      end
    }
  }
  return ret
end

puts (ippan3 30,3,7).to_s

# k = m*p + n*q
# d,p,qを与えると、
# k=d を成立させる[m,n]の配列を返す。
# [[m,n], .... ]
# これは重複も含める
# ただし、d,p,qは自然数にしか使えない
#
def ippan4 d,p,q
  ret = []
  (0..d/p).each{|m|
    di2, mo2 = (d - m*p).divmod q
    ret.push [m,di2] if mo2 == 0
  }
  return ret
end

puts (ippan4 30,3,7).to_s
puts (ippan4 166,227,-725).to_s
