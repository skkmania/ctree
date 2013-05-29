require './ctexport.rb'

describe "CTExport#to_gexf" do
  it "should make gexf string of tree" do
    ct = CTExport.new 4,[0,2,1],7,4
    print ct.to_gexf
  end
end

describe "CTExport#make_gexf_file" do
  it "should make gexf string of tree" do
    ct = CTExport.new 4,[0,2,1],7,10
    print ct.make_gexf_file('p4r7h10.gexf')
  end
end
