require '../qrange.rb'

describe QRange do
  it "should know who i am" do
    qr = QRange.new 4, [0,2,1]
    expect(qr.p).to eq 4
  end
  it "can specify index range by option" do
    qr = QRange.new 5, [0,3,2,1], {:q_index_ranges => {2=>[2,5,8], 3=>(1..4).to_a }}
    expect(qr.first).to eq [0,0,2,1]
  end
end

describe 'QRange#first' do
  it "should return first q_index" do
    qr = QRange.new 4, [0,2,1]
    expect(qr.first).to eq [0,0,0]
    qr = QRange.new 5, [0,3,2,1]
    expect(qr.first).to eq [0,0,0,0]
  end
end

describe 'QRange#last' do
  it "should return last q_index" do
    qr = QRange.new 4, [0,2,1]
    expect(qr.last).to eq [0,9,9]
  end
end

describe 'QRange#size' do
  it "should return the size of qrange" do
    qr = QRange.new 4, [0,2,1]
    expect(qr.size).to eq 100
    qr = QRange.new 5, [0,3,2,1], {:q_index_ranges => {2=>[2,5,8], 3=>(1..4).to_a }}
    expect(qr.size).to eq 120
  end
end

describe 'QRange#each' do
  it "should traverse all q_index" do
    qr = QRange.new 4, [0,2,1]
    ta = []
    qr.each{|qi| ta.push qi[1] }
    expect(ta.size).to eq 100
  end
end
