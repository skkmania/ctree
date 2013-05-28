require './ctree.rb'

describe "Node" do
  it "should know who i am" do
    n = Node.new(value:15, child:[0,2,1], parent:10, prev_move:2)
    expect( n.value ).to eq 15
    expect( n.child ).to eq [0,2,1]
    expect( n.parent ).to eq 10
    expect( n.prev_move ).to eq 2
  end
end
  
describe "Node#make_child" do
  it "should return its child level, when one branch" do
    ct = CTracer.new(p:4, q:[0,2,1], now:10)
    n = Node.new(value:10)
    ret = n.make_child(ct)
    expect(ret.class).to eq(Level)
    expect(ret.nodes.size).to eq(1)
    expect(ret.nodes[0].value).to eq 30
    expect(ret.nodes[0].prev_move).to eq 0
  end

  it "should return its child level, when two branches exist" do
    ct = CTracer.new(p:4, q:[0,2,1], now:9)
    n = Node.new(value:9)
    ret = n.make_child(ct)
    expect(ret.nodes.size).to eq(2)
    expect(ret.nodes[0].value).to eq 27
    expect(ret.nodes[0].prev_move).to eq 0
    expect(ret.nodes[1].value).to eq 2
    expect(ret.nodes[1].prev_move).to eq 2
    expect(ct.ups).to eq( { 0 => 27, 2 => 2 } )
  end
end

describe "Level#reject" do
  it "shoud delete node from self when the condition given by block is true" do
    n1 = Node.new(value:10)
    n2 = Node.new(value:15)
    lvl = Level.new nodes:[n1,n2]
    expect(lvl.nodes.size).to eq 2
    lvl.reject{|n| n.value == 15 }
    expect(lvl.nodes.size).to eq 1
  end
end

describe "Level#pp" do
  it "shoud print" do
    n1 = Node.new(value:10)
    n2 = Node.new(value:15)
    lvl = Level.new nodes:[n1,n2]
    puts
    lvl.pp
    puts
  end
end

describe "Levels#include_a_same_node?" do
  it "shoud report whether given node is included in this levels" do
    n1 = Node.new(value:10)
    n2 = Node.new(value:15)
    n3 = Node.new(value:25)
    lvl = Level.new nodes:[n1,n2]
    lvls = Levels.new levels:[lvl]
    expect( lvl.nodes.include? n1 ).to eq true
    expect( lvls.include_a_same_node? n1 ).to eq true
    expect( lvls.include_a_same_node? n2 ).to eq true
    expect( lvls.include_a_same_node? n3 ).to eq false
  end
end

describe "CTree" do
  it "should know who i am" do
  end
end

describe "CTree#set_up" do
  it "should set all levels, (4,[2,1],9,10)" do
    ct = CTree.new p:4, q:[0,2,1], root:9, height:10
    ct.set_up
    puts
    ct.pp
    expect(ct.tree_levels.size).to eq 11
  end
  it "should set all levels, (4,[5,1],9,10)" do
    ct = CTree.new p:4, q:[0,5,1], root:9, height:10
    ct.set_up
    puts
    ct.pp
    expect(ct.tree_levels.size).to eq 11
  end
end
