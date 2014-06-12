require File.dirname(__FILE__) + '/spec_helper'

describe "quickbooks matchers" do
  include QuickBooksXmlFragments

  before do
    @connection = qb_connection
  end

  it "should raise an error with an invalid but well-formed XML request" do
    xml = "<ThisIsWellFormedButInvalidXML></ThisIsWellFormedButInvalidXML>"
    @connection.
      should_receive_request(xml).
      and_return_response("<response>foo</response>")

    lambda do
      @connection.request(xml)
    end.should raise_error
  end

  it "should raise an error with a non-well-formed XML request" do
    xml = "<IAm>oh no</BadlyFormed>"
    @connection.
      should_receive_request(xml).
      and_return_response("<response>foo</response>")

    lambda do
      @connection.request(xml)
    end.should raise_error
  end

  it "should raise an error for a well-formed XML request that does not match the expectation" do
    other_xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><?qbxml version=\"6.0\"?><QBXML><QBXMLMsgsRq onError=\"continueOnError\"><CustomerAddRq requestID=\"0\"><CustomerAdd><Name>Steve Dave</Name><Phone>123-123-1234</Phone></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>"

    @connection.
      should_receive_request(valid_query_request).
      and_return_response(valid_query_response)

    lambda do
      @connection.request other_xml
    end.should raise_error
  end

  it "should not raise an error with a valid request, and return the correct response" do
    @connection.should_receive_request(valid_query_request).and_return_response(valid_query_response)

    @connection.request(valid_query_request).should == valid_query_response
  end
end