require './compact_ctree.rb'

describe "CCTree" do
  it "should know its height" do
    cct = CCTree.new p:4, q:[0,2,1], root:7, height:5
    expect(cct.height).to eq 5
  end
end

describe "CCTree#set_up" do
  it "should make tree hash" do
    cct = CCTree.new p:4, q:[0,2,1], root:7, height:4
    expect(cct.cctree.size).to eq 2
    puts JSON.pretty_generate cct.cctree
  end
  it "should make large tree hash" do
    cct = CCTree.new p:4, q:[0,2,1], root:7, height:14
    expect(cct.cctree.size).to eq 2
    puts cct.cctree.to_json
  end
end
