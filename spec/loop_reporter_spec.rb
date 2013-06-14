require '../loop_reporter.rb'

describe LoopReporter do
  it "should accept p and length of loops" do
    p = LoopReporter.new p:4, len:5, pat:"2020"
    expect(p.p).to eq 4
    expect(p.len).to eq 5
    expect(p.pattern).to eq "2020"
  end
end

describe 'LoopReporter#pattern_to_loop' do
  it "should return a loop array generated by @pattern and given number as it's starting number" do
    p = LoopReporter.new p:4, len:5, pat:"2010010"
    expect(p.pattern_to_loop 14).to eq [14,57,19,78,26,8,33]
  end
end

describe 'LoopReporter#q_to_s' do
  it "should convert an array to string, which looks pretty" do
    p = LoopReporter.new p:4, len:5, pat:"2010010"
    expect(p.q_to_s [10,200,21,1,3,5,10]).to eq "[ 10,200, 21,  1,  3,  5, 10]"
    expect(p.q_to_s [10,200,21,1032,3,5,10]).to eq "[  10, 200,  21,1032,   3,   5,  10]"
  end
end
