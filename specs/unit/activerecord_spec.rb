require 'rubygems'
require 'active_record'
require File.join(File.dirname(__FILE__), '..', 'spec_helper')

# A dummy class for mocking the activerecord connection class
class Connection;end

# StandardMethods for Address
module BiggsStandardMethods
  Biggs::Formatter::FIELDS.each do |field|
    define_method(field) do
      field == :country ? "us" : field.to_s.upcase
    end
  end
end

class FooBarEmpty < ActiveRecord::Base
  include BiggsStandardMethods
end

class FooBar < ActiveRecord::Base
  include BiggsStandardMethods
  
  biggs :postal_address
end

class FooBarCustomFields < ActiveRecord::Base
  include BiggsStandardMethods
  
  biggs :postal_address, :country => :my_custom_country_method,
                  :city => :my_custom_city_method
  
  def my_custom_country_method
    "de"
  end
  
  def my_custom_city_method
    "Hamburg"
  end
end

class FooBarCustomBlankDECountry < ActiveRecord::Base
  include BiggsStandardMethods
  
  biggs :postal_address, :blank_country_on => "de"
  
  def country
    "DE"
  end
end

class FooBarCustomMethod < ActiveRecord::Base
  include BiggsStandardMethods
  
  biggs :my_postal_address_method
end


describe "ActiveRecord Class" do
  
  it "should include Biggs::ActiveRecordAdapter" do
    FooBar.included_modules.should be_include(Biggs::ActiveRecordAdapter)
  end
  
  it "should set class value biggs_value_methods" do
    FooBar.class_eval("biggs_value_methods").should be_is_a(Hash)
    FooBar.class_eval("biggs_value_methods").size.should be_zero
  end
  
  it "should set class value biggs_instance" do
    FooBar.class_eval("biggs_instance").should be_is_a(Biggs::Formatter)
  end
  
  it "should respond to biggs" do
    FooBar.should be_respond_to(:biggs)
  end
end

describe "ActiveRecord Instance" do
  
  describe "Empty" do
    before(:each) do
      connection = mock(Connection, :columns => [])
      FooBarEmpty.stub!(:connection).and_return(connection)
    end
  
    it "should not have postal_address method" do
      FooBarEmpty.new.should_not be_respond_to(:postal_address)
    end
  end
  
  describe "Standard" do
    before(:each) do
      connection = mock(Connection, :columns => [])
      FooBar.stub!(:connection).and_return(connection)
    end
  
    it "should have postal_address method" do
      FooBar.new.should be_respond_to(:postal_address)
    end
  
    it "should return postal_address on postal_address" do
      FooBar.new.postal_address.should eql("RECIPIENT\nSTREET\nCITY STATE ZIP\nUnited States")
    end
  end

  describe "Customized Fields" do
    before(:each) do
      connection = mock(Connection, :columns => [])
      FooBarCustomFields.stub!(:connection).and_return(connection)
    end
  
    it "should return address from custom fields on postal_address" do
      FooBarCustomFields.new.postal_address.should eql("RECIPIENT\nSTREET\nZIP Hamburg\nGermany")
    end
  end

  describe "Customized Blank DE Country" do
    before(:each) do
      connection = mock(Connection, :columns => [])
      FooBarCustomBlankDECountry.stub!(:connection).and_return(connection)
    end
  
    it "should return address from custom fields on postal_address" do
      FooBarCustomBlankDECountry.new.postal_address.should eql("RECIPIENT\nSTREET\nZIP CITY\n")
    end
  end
  
  describe "Customized Blank DE Country" do
    before(:each) do
      connection = mock(Connection, :columns => [])
      FooBarCustomMethod.stub!(:connection).and_return(connection)
    end
  
    it "should have my_postal_address_method" do
      FooBarCustomMethod.new.should be_respond_to(:my_postal_address_method)
    end
    
    it "should return formatted address on my_postal_address_method" do
      FooBarCustomMethod.new.my_postal_address_method.should eql("RECIPIENT\nSTREET\nCITY STATE ZIP\nUnited States")
    end
  end

end