require '../gen_loop_patterns.rb'

describe Patterns do
  it "should accept p and length of loops" do
    p = Patterns.new p:4, len:5
    expect(p.p).to eq 4
    expect(p.len).to eq 5
  end
end

describe 'Patterns#generate_base' do
  it "should generate base array of patterns candidates" do
    p = Patterns.new p:4, len:5
    p.generate_base
    expect(p.base_array.size).to eq(3**5 - 3**4) 
    p.len = 6
    p.generate_base
    expect(p.base_array.size).to eq(3**6 - 3**5) 
    q = Patterns.new p:5, len:6
    q.generate_base
    expect(q.base_array.size).to eq(4**6 - 4**5) 
  end
end

describe 'Patterns#delete_series_of_nonzero_digit' do
  it "should delete elements from base_array which contains any series of nonzero_digits" do
    p = Patterns.new p:4, len:5
    p.generate_base
    expect(p.base_array.include? "11011").to eq(true)
    expect(p.base_array.include? "11111").to eq(true)
    expect(p.base_array.include? "10220").to eq(true)
    expect(p.base_array.include? "10200").to eq(true)
    expect(p.base_array.include? "10201").to eq(true)
    p.delete_series_of_nonzero_digit
    expect(p.base_array.include? "11011").to eq(false)
    expect(p.base_array.include? "11111").to eq(false)
    expect(p.base_array.include? "10220").to eq(false)
    expect(p.base_array.include? "10200").to eq(true)
    expect(p.base_array.include? "10201").to eq(true)
  end
end

describe 'Patterns#delete_if_both_side_is_nonzero_digit' do
  it "should delete elements from base_array if the element has nonzero_digits at both sides" do
    p = Patterns.new p:4, len:5
    p.generate_base
    expect(p.base_array.include? "11011").to eq(true)
    expect(p.base_array.include? "10002").to eq(true)
    expect(p.base_array.include? "10220").to eq(true)
    expect(p.base_array.include? "10201").to eq(true)
    p.delete_if_both_side_is_nonzero_digit
    expect(p.base_array.include? "11011").to eq(false)
    expect(p.base_array.include? "10002").to eq(false)
    expect(p.base_array.include? "10220").to eq(true)
    expect(p.base_array.include? "10201").to eq(false)
  end
end

describe 'Patterns#delete_if_00_not_found' do
  it "should delete elements from base_array if the element does not have any 0 series" do
    p = Patterns.new p:4, len:5
    p.generate_base
    expect(p.base_array.include? "10101").to eq(true)
    expect(p.base_array.include? "20202").to eq(true)
    expect(p.base_array.include? "10020").to eq(true)
    expect(p.base_array.include? "10200").to eq(true)
    p.delete_if_00_not_found
    expect(p.base_array.include? "10101").to eq(false)
    expect(p.base_array.include? "20202").to eq(false)
    expect(p.base_array.include? "10020").to eq(true)
    expect(p.base_array.include? "10200").to eq(true)
  end
end

describe 'Patterns#delete_if_cycle_occurs' do
  it "should delete elements from base_array if the element is totally composed with cycles" do
    p = Patterns.new p:4, len:6
    p.generate_base
    expect(p.base_array.include? "101010").to eq(true)
    expect(p.base_array.include? "200200").to eq(true)
    expect(p.base_array.include? "101011").to eq(true)
    expect(p.base_array.include? "220202").to eq(true)
    p.delete_if_cycle_occurs
    expect(p.base_array.include? "101010").to eq(false)
    expect(p.base_array.include? "200200").to eq(false)
    expect(p.base_array.include? "101011").to eq(true)
    expect(p.base_array.include? "220202").to eq(true)
  end
end

describe 'Patterns#rotate_duplication_check' do
  it "should delete elements from base_array if the rotation of the element is in base_array" do
    p = Patterns.new p:4, len:4
    p.generate_base
    expect(p.base_array.include? "1020").to eq(true)
    expect(p.base_array.include? "2010").to eq(true)
    expect(p.base_array.include? "2020").to eq(true)
    expect(p.base_array.include? "1000").to eq(true)
    expect(p.base_array.include? "1010").to eq(true)
    p.rotate_duplication_check
    expect(p.base_array.include? "1020").to eq(false)
    expect(p.base_array.include? "2010").to eq(true)
    expect(p.base_array.include? "2020").to eq(true)
    expect(p.base_array.include? "1000").to eq(true)
    expect(p.base_array.include? "1010").to eq(true)
  end
  it "should delete elements from base_array if the rotation of the element is in base_array" do
    p = Patterns.new p:4, len:5
    p.generate_base
    expect(p.base_array.include? "10020").to eq(true)
    expect(p.base_array.include? "10200").to eq(true)
    expect(p.base_array.include? "10000").to eq(true)
    p.rotate_duplication_check
    expect(p.base_array.include? "10020").to eq(false)
    expect(p.base_array.include? "10200").to eq(false)
    expect(p.base_array.include? "10000").to eq(true)
  end
end

describe 'Patterns#plus_minus_check' do
  it "should delete elements from base_array if the balance of num of 0 in the element results x to be minus" do
    p = Patterns.new p:4, len:9
    p.generate_base
    expect(p.base_array.include? "101010100").to eq(true)
    p.plus_minus_check
    expect(p.base_array.include? "101010100").to eq(false)

    p = Patterns.new p:5, len:9
    p.generate_base
    p.delete_series_of_nonzero_digit
    p.delete_if_both_side_is_nonzero_digit
    p. delete_if_00_not_found
    expect(p.base_array.include? "101010100").to eq(true)
    p.plus_minus_check
    expect(p.base_array.include? "101010100").to eq(true)
  end
end

describe 'Patterns#return_array' do
  it "should return final result" do
    p = Patterns.new p:4, len:5
    p.return_array
    puts p.base_array.to_s
    expect(p.base_array.size).to eq(6)
    expect(["10000", "10100", "20000", "20010", "20100", "20200"] - p.base_array).to eq([])
    expect(p.base_array - ["10000", "10100", "20000", "20010", "20100", "20200"]).to eq([])
  end
  it "should return final result" do
    p = Patterns.new p:4, len:4
    p.return_array
    puts p.base_array.to_s
    expect(p.base_array - ["1000", "1010", "2000", "2010", "2020"]).to eq([])
    expect(["1000", "1010", "2000", "2010", "2020"] - p.base_array).to eq([])
  end
end

