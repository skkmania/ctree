require './gen_q_loop_table.rb'

describe QLoopTable do
  it "should know who i am" do
    qlt = QLoopTable.new p:3
    expect(qlt.p).to eq 3
  end

  it "can accept q_foumula_collection.txt" do
    qlt = QLoopTable.new p:3,opt:{:collection => 'data/p3_qformula_collection.txt' }
    expect(qlt.collection).to eq 'data/p3_qformula_collection.txt'
  end

  it "shuld access GoogleDrive spreadsheet" do
    qlt = QLoopTable.new p:3,opt:{:spreadsheet => 'p3_Q_Loop_Table' }
    expect(qlt.spreadsheet).to eq 'p3_Q_Loop_Table'
    qlt.start_gdrive
    expect(qlt.key).to eq '0AtsWWiWPzmSbdGRHNmFjNzdISDB0U3JKQmVybVZPMWc'
    expect(qlt.session.class).to eq GoogleDrive::Session
    expect(qlt.ws.class).to eq GoogleDrive::Session
  end
end

describe "QLoopTable#put_q_labels" do
  it "shoud input q in column 0 as label of q" do
    qlt = QLoopTable.new p:3,opt:{:spreadsheet => 'p3_Q_Loop_Table' , :top_left => [6,2]}
    qlt.start_gdrive
    qlt.put_q_labels 3000
    expect(qlt.ws.num_rows).to eq 3006
  end
end
    
describe "QLoopTable#read_pattern_and_formula" do
  it "shoud read pattern, formula from collection file" do
    qlt = QLoopTable.new p:3,opt:{:collection => 'data/p3_qformula_collection.txt' }
    qlt.read_pattern_and_formula 13
    expect(qlt.patterns.size).to eq 117
  end
end
    
describe "QLoopTable#put_formula_labels" do
  it "shoud input pattern, formula in row 1 - 4 as the label of loops" do
    qlt = QLoopTable.new p:3,opt:{:collection => 'data/p3_qformula_collection.txt',:spreadsheet => 'p3_Q_Loop_Table' , :top_left => [6,2]}
    qlt.read_pattern_and_formula 13
    qlt.start_gdrive
    qlt.put_formula_labels
    expect(qlt.ws.num_cols).to eq 118
  end
end

describe "QLoopTable#put_loops" do
  it "shoud input a cloumn of loops" do
    qlt = QLoopTable.new p:3,opt:{:collection => 'data/p3_qformula_collection.txt',:spreadsheet => 'p3_Q_Loop_Table' , :top_left => [6,2]}
    qlt.start_gdrive
    qlt.put_loops 6, 3, 5, 1, '1000'
    expect(qlt.ws.num_cols).to eq 118
  end
end

describe "QLoopTable#put_all" do
  it "shoud complete the table of q and loops" do
    qlt = QLoopTable.new p:3,opt:{:collection => 'data/p3_qformula_collection.txt',:spreadsheet => 'p3_Q_Loop_Table' , :top_left => [6,2]}
    qlt.start_gdrive
    qlt.put_q_labels
    qlt.read_pattern_and_formula 13
    qlt.put_formula_labels
    qlt.put_all
    expect(qlt.ws.num_cols).to eq 118
  end
end

describe "QLoopTable#read_formula" do
  it "shoud read parameter from given formula" do
    qlt = QLoopTable.new p:3,opt:{:collection => 'data/p3_qformula_collection.txt',:spreadsheet => 'p3_Q_Loop_Table' , :top_left => [6,2]}
    expect(qlt.read_formula 'x == 1/29*q1').to eq [1,29]
    expect(qlt.read_formula 'x == 5/23*q1').to eq [5,23]
  end
end

describe "QLoopTable#expand" do
  it "shoud generate loop string" do
    qlt = QLoopTable.new p:3,opt:{:collection => 'data/p3_qformula_collection.txt',:spreadsheet => 'p3_Q_Loop_Table' , :top_left => [6,2]}
    expect(qlt.expand(5,'100',5)).to eq '5, 20, 10'
    expect(qlt.expand(25,'1000',5)).to eq '5, 40, 20, 10'
    expect(qlt.expand(21,'100010',33)).to eq '33, 120, 60, 30, 15, 66'
  end
end
