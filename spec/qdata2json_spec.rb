require './qdata2json.rb'

describe QD2JS do
  it "should know who am i" do
    qj = QD2JS.new p:4, len:5
    expect(qj.p).to eq 4
    expect(qj.len).to eq 5
  end
end

describe "QD2JS#pat2expr" do
  it "should generate expression from pattern" do
    qj = QD2JS.new p:4, len:5
    expect(qj.pat2expr "100").to eq "((p*(x)+q[1])/r)/r"
    expect(qj.pat2expr "1010").to eq "(p*((p*(x)+q[1])/r)+q[1])/r"
    expect(qj.pat2expr "1020").to eq "(p*((p*(x)+q[1])/r)+q[2])/r"
    expect(qj.pat2expr "20100").to eq "((p*((p*(x)+q[2])/r)+q[1])/r)/r"
  end
end

describe "QD2JS#expr2lambda" do
  it "should return lambda f" do
    qj = QD2JS.new p:4, len:5
    f = qj.expr2lambda "(p*((p*(x)+q[1])/r)+q[1])/r"
    expect( f.call(7, 4, [0,2,1], 3) ).to eq 14
  end
end



