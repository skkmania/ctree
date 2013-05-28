require './ctracer.rb'

describe "CTracer" do
  it "should know where i am" do
    ct = CTracer.new(p:4, q:[0,2,1], now:10)
    expect( ct.p ).to eq 4
    expect( ct.q ).to eq [0,2,1]
    expect( ct.now ).to eq 10
  end
end

describe "CTracer#validate_q" do
  it "q requires (p - 1) elements" do
    expect { CTracer.new(p:4, q:[2,1], now:10) }.to raise_error CTValidateQError
  end
  it "each elements of q must be (standard q value + @r * integer)" do
    expect { CTracer.new(p:4, q:[0,2,2], now:10) }.to raise_error CTValidateQError
    expect { CTracer.new(p:6, q:[0,4,18,12,10], now:10) }.to raise_error CTValidateQError
  end
end

describe "CTracer#down" do
  it "should go 1 step near to root" do
    ct = CTracer.new(p:4, q:[0,2,1], now:12)
    ct.down
    ct.now == 4
    ct = CTracer.new(p:4, q:[0,2,1], now:10)
    ct.down
    ct.now == 42
  end
end

describe "CTracer#type" do
  it "should show the type of this node" do
    ct = CTracer.new(p:4, q:[0,2,1], now:10)
    ct.type == 2
  end
end

describe "CTracer#ups" do
  it "should return the hash of the values of this node's up branches" do
    ct = CTracer.new(p:4, q:[0,2,1], now:10)
    expect(ct.ups).to eq( { 0 => 30 } )
    ct = CTracer.new(p:4, q:[0,2,1], now:9)
    expect(ct.ups).to eq( { 0 => 27, 2 => 2 } )
    ct = CTracer.new(p:4, q:[0,5,1], now:189)
    expect(ct.ups).to eq( { 0 => 567, 1 => 46, 2 => 47 } )
  end
end

describe "CTracer#branches" do
  it "should show the number of this node's up branches" do
    ct = CTracer.new(p:4, q:[0,2,1], now:10)
    expect(ct.branches).to eq 1
    ct = CTracer.new(p:4, q:[0,2,1], now:9)
    expect(ct.branches).to eq 2
    ct = CTracer.new(p:4, q:[0,5,1], now:189)
    expect(ct.branches).to eq 3
  end
end

describe "CTracer#up" do
  it "should give a method which accepts direction and follow it" do
    ct = CTracer.new(p:4, q:[0,2,1], now:10)
    ct.up.call(0)
    ct.now == 30
  end
  it "should give a method which accepts direction and follow it" do
    ct = CTracer.new(p:4, q:[0,5,1], now:189)
    ct.up.call(0)
    expect(ct.now).to eq 567
    ct.down
    ct.up.call(1)
    expect(ct.now).to eq 46
    ct.down
    ct.up.call(2)
    expect(ct.now).to eq 47
  end
  it "should give a method which accepts impossible direction and raise exception" do
    ct = CTracer.new(p:4, q:[0,2,1], now:10)
    expect { ct.up.call(1)}.to raise_error CTDirectionError
    expect { ct.up.call(2)}.to raise_error CTDirectionError
  end
end

