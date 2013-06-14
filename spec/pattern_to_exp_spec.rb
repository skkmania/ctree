require '../pattern_to_exp.rb'

describe Parser do
  it "should accept p and q of loop" do
    p = Parser.new p:4, q:[0,2,1]
    expect(p.p).to eq 4
    expect(p.q).to eq [0,2,1]
  end
end

describe 'Parser#tracable?' do
  it "should tell whether given x can follow the pattern in accordance with pn+q rules" do
    p = Parser.new p:4, q:[0,2,1], pat:"1010"
    expect(p.tracable? 1).to eq false
    expect(p.tracable? 2).to eq false
    expect(p.tracable? 7).to eq true
  end
end

describe 'Parser#parse' do
  it "should parse a pattern string and return a tree as an array" do
    p = Parser.new p:4, q:[0,2,1]
    p.parse("2")
    expect(p.tree).to eq [:+, [:*, 4, :x], 1]
    p.parse("0")
    expect(p.tree).to eq [:div, :x, 3]
    p.parse("1")
    expect(p.tree).to eq                            [:+, [:*, 4, :x], 2]
    p.parse("10")
    expect(p.tree).to eq                     [:div, [:+, [:*, 4, :x], 2], 3]
    p.parse("101")
    expect(p.tree).to eq        [:+, [:*, 4, [:div, [:+, [:*, 4, :x], 2], 3]], 2]
    p.parse("1010")
    expect(p.tree).to eq [:div, [:+, [:*, 4, [:div, [:+, [:*, 4, :x], 2], 3]], 2], 3]
  end
end

describe 'Parser#evaluate' do
  it "should return value of this instance's tree" do
    p = Parser.new p:4, q:[0,2,1]
    p.parse("0")
    expect(p.tree).to eq [:div, :x, 3]
    expect(p.evaluate 3).to eq 1
    p.parse("1")
    expect(p.tree).to eq [:+, [:*, 4, :x], 2]
    expect(p.evaluate 1).to eq 6
    p.parse("2")
    expect(p.tree).to eq [:+, [:*, 4, :x], 1]
    expect(p.evaluate 2).to eq 9
    p.parse("20")
    expect(p.tree).to eq [:div, [:+, [:*, 4, :x], 1], 3]
    expect(p.evaluate 2).to eq 3
    p.parse("200")
    expect(p.tree).to eq [:div, [:div, [:+, [:*, 4, :x], 1], 3], 3]
    expect(p.evaluate 2).to eq 1
    p.parse("10")
    expect(p.tree).to eq [:div, [:+, [:*, 4, :x], 2], 3]
    expect(p.evaluate 1).to eq 2
    p.parse("101")
    expect(p.tree).to eq [:+, [:*, 4, [:div, [:+, [:*, 4, :x], 2], 3]], 2]
    expect(p.evaluate 7).to eq 42
    p.parse("1010")
    expect(p.tree).to eq [:div, [:+, [:*, 4, [:div, [:+, [:*, 4, :x], 2], 3]], 2], 3]
    expect(p.evaluate 7).to eq 14
  end
end

describe 'Parser#loop_check' do
  it "should tell whether given p,q,x,pattern can make a loop" do
    p = Parser.new p:4, q:[0,17,85], pat:"200"
    p.parse
    expect(p.tree).to eq [:div, [:div, [:+, [:*, 4, :x], 85], 3], 3]
    expect(p.loop_check 17).to eq true
    expect(p.loop_check 8).to eq false
    p.pattern = "1010100"
    p.parse
    expect(p.loop_check 37).to eq true
    p.pattern = "1010200"
    p.parse
    expect(p.loop_check 73).to eq true
    p.pattern = "2010100"
    p.parse
    expect(p.loop_check 101).to eq true
  end
end
