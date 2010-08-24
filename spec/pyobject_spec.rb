require File.dirname(__FILE__) + '/spec_helper.rb'

describe RubyPython::PyObject do
  include RubyPythonStartStop
  include TestConstants

  before do
    @string = RubyPython.import('string').pObject
    @urllib2 = RubyPython.import('urllib2').pObject
    @builtin = RubyPython.import("__builtin__")
    sys = RubyPython.import 'sys'
    sys.path.append './spec/python_helpers/'
    @objects = RubyPython.import('objects')
  end

  describe ".new" do
    [
      ["a string", AString],
      ["an int", AnInt],
      ["a float", AFloat],
      ["an array", AnArray],
      ["a symbol", ASym],
      ["a hash", AHash]
    ].each do |title, obj|

      it "should wrap #{title}" do
        lambda { described_class.new(obj) }.should_not raise_exception
      end
    end


  end #new

  describe "#rubify" do

    [
      ["a string", AString],
      ["an int", AnInt],
      ["a float", AFloat],
      ["an array", AnArray],
      ["a symbol", ASym, ASym.to_s],
      ["a hash", AHash, AConvertedHash]
    ].each do |arr|
      type, input, output = arr
      output ||= input

      it "should faithfully unwrap #{type}" do
        described_class.new(input).rubify.should == output
      end

    end

  end #rubify

  describe "#hasAttr" do
    it "should return true when object has the requested attribute" do
      @string.hasAttr("ascii_letters").should be_true
    end

    it "should return false when object does not have the requested attribute" do
      @string.hasAttr("nonExistentThing").should be_false
    end
  end

  describe "#getAttr" do
    it "should fetch requested object attribute" do 
      ascii_letters = @string.getAttr "ascii_letters"
      ascii_letters.rubify.should == "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    end

    it "should return a PyObject instance" do
      ascii_letters = @string.getAttr "ascii_letters"
      ascii_letters.should be_kind_of(described_class)
    end
  end

  describe "#setAttr" do 
    it "should modify the specified attribute of the object" do
      pyNewLetters = described_class.new "RbPy"
      @string.setAttr "ascii_letters", pyNewLetters
      @string.getAttr("ascii_letters").rubify.should == pyNewLetters.rubify
    end

    it "should create the requested attribute if it doesn't exist" do 
      pyNewString = described_class.new "python"
      @string.setAttr "ruby", pyNewString
      @string.getAttr("ruby").rubify.should == pyNewString.rubify
    end
  end

  describe "#cmp" do

    before do
      @less = described_class.new 5
      @greater = described_class.new 10
      @less_dup = described_class.new 5
    end

    it "should return 0 when objects are equal" do
      @less.cmp(@less_dup).should == 0
    end

    it "should change sign under interchange of arguments" do 
      @less.cmp(@greater).should == -@greater.cmp(@less)
    end

    it "should return -1 when first object is less than the second" do
      @less.cmp(@greater).should == -1
    end
    
    it "should return 1 when first object is greater than the second" do
      @greater.cmp(@less).should == 1
    end
  end

  describe "#makeTuple" do
    #Try to expand coverage here
    it "should wrap single arguments in a tuple" do
      arg = described_class.new AString
      described_class.makeTuple(arg).rubify.should == [AString]
    end
  end

  describe "#callObject" do
    #Expand coverage types
    it "should execute wrapped object with supplied arguments" do
      arg = described_class.new AnInt
      argt = described_class.makeTuple arg

      builtin = @builtin.pObject
      stringClass = builtin.getAttr "str"
      stringClass.callObject(argt).rubify.should == AnInt.to_s
    end
  end

  describe "#newList" do
    it "should wrap supplied args in a Python list" do
      args = AnArray.map do |obj|
        described_class.new obj
      end
      described_class.newList(*args).rubify.should == AnArray
    end
  end

  describe "#functionOrMethod?" do

    it "should be true for a method" do
      mockObjClass = @objects.RubyPythonMockObject.pObject
      mockObjClass.getAttr('square_elements').should be_a_functionOrMethod
    end

    it "should be true for a function" do
      @objects.pObject.getAttr('identity').should be_a_functionOrMethod
    end

    xit "should return true for a builtin function" do
      any = @builtin.pObject.getAttr('any')
      any.should be_a_functionOrMethod
    end

    it "should return false for a class" do
      @objects.RubyPythonMockObject.pObject.should_not be_a_functionOrMethod
    end

  end

  describe "#class?" do

    it "should return true if wrapped object is an old style class" do
      @objects.RubyPythonMockObject.pObject.should be_a_class
    end

    it "should return true if wrapped object is an new style class" do
      @objects.NewStyleClass.pObject.should be_a_class
    end

    it "should return true if wrapped object is a builtin class" do
      strClass = @builtin.pObject.getAttr('str')
      strClass.should be_a_class
    end

    it "should return false for an object instance" do
      @objects.RubyPythonMockObject.new.pObject.should_not be_a_class
    end

  end

end

