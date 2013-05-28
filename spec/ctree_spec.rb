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

describe "CTree" do
  it "should know who i am" do
  end
end

describe "CTree#set_up" do
  it "should set all levels" do
    ct = CTree.new p:4, q:[0,2,1], root:9, height:10
    ct.set_up
puts
    (0..10).each{|i|
      ct.tree_levels[i].levels.each{|lvl|
        print lvl.nodes.map{|n| n.value }.to_s + ", "
      }
      puts
    }
    expect(ct.tree_levels.size).to eq 11
  end
end
