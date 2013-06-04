require './tryout.rb'

describe TryOut do
  before do
    @to = TryOut.new 4,[0,2,1], 123456789
    @to.go_steps 30
  end

  it "should know who i am" do
    expect(@to.p).to eq 4
  end

  it "should accept target and process 30 down steps" do
    expect(@to.trail.size).to eq 31
    puts
    puts @to.trail.map(&:to_s).join(",")
  end

  it "should tell the trail of 30 steps" do
    str = @to.moves_history.map(&:to_s).join
    puts str
    expect(str.size).to eq 30
  end

  describe "TryOut#min" do
    it "should tell min value of 30 steps" do
      min = @to.trail.min
      puts "\nmin : #{min}"
      expect(min).to be < @to.tgt
    end
  end

  describe "TryOut#max_0_len" do
    it "should tell the length of longest move-0 series and the value just after the longest move-0 series" do
      m0len, mvalue = @to.max_0_len
      puts "\nlen: #{m0len},  val: #{mvalue}"
      expect(m0len).to be > 1
      expect(mvalue).to be > 1
    end
  end

end

describe "TryOut#set_google" do
end

describe "TryOut#add_sheet" do
  it "should add a sheet to spread sheet" do
    to = TryOut.new 4,[0,2,1], 123456789012345678901234567890
    to.set_google './.googledrive.conf'
    to.add_sheet to.tgt.to_s
  end

  it "should set the name of the sheet" do
  end
end

describe "TryOut#write_sheet" do
  it "should add a sheet to spread sheet" do
    to = TryOut.new 4,[0,2,1], 123456789012345678901234567890
    to.set_google './.googledrive.conf'
    to.add_sheet to.tgt.to_s
    to.go_steps 30
    to.write_sheet
  end
end
  
describe "TryOut#count_to_q" do
  it "should convert a integer to an array of q" do
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    to.q_count = 111
    to.count_to_q
    expect(to.q).to eq [0,5,4,9,8,7]
    to.q_count = 31211
    to.count_to_q
    expect(to.q).to eq [0,23,10,15,8,7]
  end
end

describe "TryOut#next_q" do
  it "should give a new array of q" do
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    expect(to.q_count).to eq 0
    expect(to.q).to eq [0,5,4,3,2,1]
    to.next_q
    expect(to.q_count).to eq 1
    expect(to.q).to eq [0,5,4,3,2,7]
    to.next_q
    expect(to.q_count).to eq 2
    expect(to.q).to eq [0,5,4,3,2,13]
    10.times{ to.next_q }
    expect(to.q_count).to eq 12
    expect(to.q).to eq [0,5,4,3,8,13]
  end
end

describe "TryOut#set_q_index_ranges" do
  it "should update @q_index_ranges from a string" do
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    to.set_q_index_ranges '{ 3 => (10..15).to_a }'
    expect(to.q_index_ranges[1]).to eq (0..9).to_a
    expect(to.q_index_ranges[3]).to eq (10..15).to_a
  end
end

describe "TryOut#q_index_to_q" do
  it "should generate q from q_index" do
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    to.q_index = [0,0,1,0,3,2]
    to.q = to.q_index_to_q
    expect(to.q).to eq [0,5,10,3,20,13]
  end
end

describe "TryOut#q_to_q_index" do
  it "should generate q_index from chrrent @q" do
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    expect(to.q_index).to eq [0,0,0,0,0,0]
  end
end

describe "TryOut#next_q_index" do
  context "in defalut q_index_ranges" do
    it "should update @q to the next to current" do
      to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
      expect(to.q_index).to eq [0,0,0,0,0,0]
      to.next_q_index
      expect(to.q_index).to eq [0,0,0,0,0,1]
      8.times{ to.next_q_index }
      expect(to.q_index).to eq [0,0,0,0,0,9]
      to.next_q_index
      expect(to.q_index).to eq [0,0,0,0,1,0]
    end
  end
  context "in customized q_index_ranges" do
    it "should update @q to the next to current" do
      to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
      to.set_q_index_ranges '{ 4 => [5,6,7], 5 => [1,2,3,4] }'
      expect(to.q_index).to eq [0,0,0,0,5,1]
      to.next_q_index
      expect(to.q_index).to eq [0,0,0,0,5,2]
      2.times{ to.next_q_index }
      expect(to.q_index).to eq [0,0,0,0,5,4]
      to.next_q_index
      expect(to.q_index).to eq [0,0,0,0,6,1]
      3.times{ to.next_q_index }
      expect(to.q_index).to eq [0,0,0,0,6,4]
      to.next_q_index
      expect(to.q_index).to eq [0,0,0,0,7,1]
      4.times{ to.next_q_index }
      expect(to.q_index).to eq [0,0,0,1,5,1]
      12.times{ to.next_q_index }
      expect(to.q_index).to eq [0,0,0,2,5,1]
      4.times{ to.next_q_index }
      expect(to.q_index).to eq [0,0,0,2,6,1]
    end
  end
end

describe "TryOut#chk_non_effective_q" do
  it "should give an array of [(q which does not exist in moves_history)'s digit position in @q_count number]." do
    # この意味は日本語でよく説明しないとすぐにわからなくなりそうだww
    # 目的としては、
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    to.moves_history = [3,0,4,0,3,0,2,0,1,0,0,5,0,0,1]
    expect(to.chk_non_effective_q).to eq []
    to.moves_history = [3,0,4,0,3,0,2,0,0,0,5,0,0,1]
    expect(to.chk_non_effective_q).to eq [5]
    to.moves_history = [3,0,4,0,3,0,2]
    expect(to.chk_non_effective_q).to eq [5,4,1]
    to.moves_history = [3,0,4,0,3,0,2,0]
    expect(to.chk_non_effective_q).to eq [5,1]
  end
end

describe "TryOut#make_pass_list" do
  it "should give an array of q_count which should be passed." do
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    to.moves_history = [3,0,4,0,3,0,2,0,1,0,0,5,0,0,1]
    expect(to.pass_list).to eq []
    to.make_pass_list
    expect(to.pass_list).to eq []
  end
  it "should give an array of q_count which should be passed." do
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    to.moves_history = [3,0,4,0,3,0,2,0,0,0,5,0,0,1]
    expect(to.pass_list).to eq []
    to.make_pass_list
    expect(to.pass_list).to eq [10000,20000,30000,40000,50000,60000,70000,80000,90000]
    # q[1] はmoves_historyに寄与しないのだから q[1]を変化させる必要はない、という意味になる
  end
  it "should give an array of q_count which should be passed." do
    to = TryOut.new(7,[0,5,4,3,2,1], 123456789012345678901234567890,'dummy')
    to.moves_history = [3,0,4,0,3,0,2]
    expect(to.pass_list).to eq []
    to.make_pass_list
    expect(to.pass_list.size).to eq 999
    expect(to.pass_list.include? 10000).to be_true
    expect(to.pass_list.include? 11000).to be_true
    expect(to.pass_list.include? 11001).to be_true
    # q[1],q[2],q[5] はmoves_historyに寄与しないのだから q[1],q[2],q[5]を変化させる必要はない、という意味になる
  end
end
