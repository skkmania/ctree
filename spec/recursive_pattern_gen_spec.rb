require './recursive_pattern_gen.rb'

describe PGen do
  it "should know self" do
    pg = PGen.new p:3, now:'10'
    expect(pg.now).to eq '10'
  end
end

describe 'PGen#ups' do
  it "should return the array of its children" do
    pg = PGen.new p:3, now:'10'
    expect(pg.ups).to eq ['100', '101' ]
  end
end

describe PatternTree do
  it "should know self" do
    pt = PatternTree.new p:3, q:[0,1], root:'10', height:3
    expect(pt.height).to eq 3
    expect(pt.ptree).to eq(
   {"data"=>"10",
    "valid" => false,
    "children"=>[{"data"=>"100",
                  "valid" => true,
                  "children"=>[{"data"=>"1000",
                                "valid" => true,
                                "children"=>[{"data"=>"10000",
                                              "valid" => true,
                                              "children"=>[]},
                                             {"data"=>"10001",
                                              "valid" => false,
                                              "children"=>[]}
                                            ]
                               },
                               {"data"=>"1001",
                                "valid" => false,
                                "children"=>[{"data"=>"10010",
                                              "valid" => true,
                                              "children"=>[]},
                                            ]
                               }
                              ]
                 },
                 {"data"=>"101",
                  "valid" => false,
                  "children"=>[{"data"=>"1010",
                                "valid" => false,
                                "children"=>[{"data"=>"10100",
                                              "valid" => true,
                                              "children"=>[]},
                                             {"data"=>"10101",
                                              "valid" => false,
                                              "children"=>[]}]}
                               ]}
                  ]})
  end
end
