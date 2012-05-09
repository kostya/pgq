require File.dirname(__FILE__) + '/spec_helper'

describe Pgq::Marshal64Coder do
  before :each do
    @coder = Pgq::Marshal64Coder
  end

  it "work" do
    data = {:a => [1, 2, 3, {:b => 'c'}]}
    s = @coder.dump(data)
    @coder.load(s).should == data
  end

  it "work on large data" do
    data = {}
    10000.times{|i| data["#{i}".to_sym] = [i, "i_#{i}"]}
    
    s = @coder.dump(data)
    @coder.load(s).should == data
  end
  
end