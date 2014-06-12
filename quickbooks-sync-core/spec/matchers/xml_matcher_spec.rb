require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XmlMatchers::XmlMatcher do
  include XmlMatchers
  it "should match identical plain text" do
    "<b>foo</b>".should be_xml("<b>foo</b>")
  end

  it "should not match different plain text" do
    "<b>bar</b>".should_not be_xml("<b>foo</b>")
  end

  it "should match identical attributes" do
    '<foo attr="val" />'.should be_xml('<foo attr="val" />')
  end

  it "should not match different attributes" do
    '<foo attr="val1" />'.should_not be_xml('<foo attr="val2" />')
  end

  it "should match identical attributes out of order" do
    '<foo a1="a" a2="b" />'.should be_xml('<foo a2="b" a1="a" />')
  end

  it "should match with equal children" do
    '<foo><bar /><eggs /></foo>'.should be_xml('<foo><bar /><eggs /></foo>')
  end

  it "should not match different numbers of children" do
    '<foo><bar /></foo>'.should_not be_xml('<foo><bar /><eggs /></foo>')
  end

  it "should match deeply nested text" do
    '<a><b><c><d>value</d></c></b></a>'.should be_xml('<a><b><c><d>value</d></c></b></a>')
  end

  it "should not match different deeply nested text" do
    '<a><b><c><d>value</d></c></b></a>'.should_not be_xml('<a><b><c><d>other</d></c></b></a>')
  end

  it "should ignore whitespace" do
    '<a>         <b />  </a>'.should be_xml('<a><b /></a>')
  end

  it "should work with empty strings" do
    "".should be_xml("")
  end

  it "should tell XML is different than an empty string" do
    "<foo />".should_not be_xml("")
    "".should_not be_xml("<foo />")
  end

end