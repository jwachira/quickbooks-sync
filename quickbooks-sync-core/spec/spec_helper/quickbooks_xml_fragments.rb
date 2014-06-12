module QuickBooksXmlFragments

  def valid_customer_add_response
    %q{
      <QBXML>
        <QBXMLMsgsRs>
          <CustomerAddRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
            <CustomerRet>
              <ListID>800000D5-1271699206</ListID>
              <TimeCreated>2010-04-19T10:46:46-08:00</TimeCreated>
              <TimeModified>2010-04-19T10:46:46-08:00</TimeModified>
              <EditSequence>1271699206</EditSequence>
              <Name>Steve Dave</Name>
              <FullName>Steve Dave of Nazareth</FullName>
              <IsActive>true</IsActive>
              <Sublevel>0</Sublevel>
              <Balance>0.00</Balance>
              <TotalBalance>0.00</TotalBalance>
              <JobStatus>None</JobStatus>
            </CustomerRet>
          </CustomerAddRs>
        </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_empty_customer_query_response
    %q{
      <QBXML>
        <QBXMLMsgsRs>
          <CustomerQueryRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
          </CustomerQueryRs>
        </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_customer_query_response
    %q{
      <QBXML>
        <QBXMLMsgsRs>
          <CustomerQueryRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
            <CustomerRet>
              <ListID>40000-1236889264</ListID>
              <TimeCreated>2009-03-12T13:21:04-08:00</TimeCreated>
              <TimeModified>2009-03-12T13:21:47-08:00</TimeModified>
              <EditSequence>1236889307</EditSequence>
              <Name>Builder's Supply LLC</Name>
              <FullName>Builder's Supply LLC</FullName>
              <IsActive>true</IsActive>
              <Sublevel>0</Sublevel>
              <BillAddress>
                <Addr1>Builder's Supply LLC</Addr1>
              </BillAddress>
              <BillAddressBlock>
                <Addr1>Builder's Supply LLC</Addr1>
              </BillAddressBlock>
              <TermsRef>
                <ListID>10000-1236889119</ListID>
                <FullName>Net 10</FullName>
              </TermsRef>
              <Balance>2334.00</Balance>
              <TotalBalance>2334.00</TotalBalance>
              <SalesTaxCodeRef>
                <ListID>20000-1229303705</ListID>
                <FullName>Non</FullName>
              </SalesTaxCodeRef>
              <JobStatus>None</JobStatus>
            </CustomerRet>
          </CustomerQueryRs>
        </QBXMLMsgsRs>
      </QBXML>

    }
  end

  def valid_query_request
    %q{
      <QBXML>
         <QBXMLMsgsRq onError="stopOnError">
           <CreditMemoQueryRq iterator="Start" requestID="0">
              <MaxReturned>500</MaxReturned>
              <IncludeLineItems>1</IncludeLineItems>
           </CreditMemoQueryRq>
            <CustomerQueryRq requestID="1" iterator="Start">
               <MaxReturned>500</MaxReturned>
            </CustomerQueryRq>
            <InvoiceQueryRq requestID="2" iterator="Start">
               <MaxReturned>500</MaxReturned>
               <IncludeLineItems>1</IncludeLineItems>
            </InvoiceQueryRq>
            <ItemQueryRq requestID="3" iterator="Start">
               <MaxReturned>500</MaxReturned>
            </ItemQueryRq>
            <PaymentMethodQueryRq requestID="4">
               <MaxReturned>500</MaxReturned>
            </PaymentMethodQueryRq>
         </QBXMLMsgsRq>
      </QBXML>
    }
  end

  def valid_query_response
    %q{
      <QBXML>
      <QBXMLMsgsRs>
      <CustomerQueryRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
      <CustomerRet>
      <ListID>8000000E-1273520333</ListID>
      <TimeCreated>2010-05-10T12:38:53-08:00</TimeCreated>
      <TimeModified>2010-05-18T15:20:20-08:00</TimeModified>
      <EditSequence>1273799447</EditSequence>
      <Name>Harold R2</Name>
      <FullName>Harold R2</FullName>
      <IsActive>true</IsActive>
      <Sublevel>0</Sublevel>
      <FirstName>Harold</FirstName>
      <LastName>Q3</LastName>
      <BillAddress>
      <Addr1>Harold Donaldson</Addr1>
      </BillAddress>
      <BillAddressBlock>
      <Addr1>Harold Donaldson</Addr1>
      </BillAddressBlock>
      <Contact>Harold Donaldson</Contact>
      <Balance>10.00</Balance>
      <TotalBalance>10.00</TotalBalance>
      <JobStatus>None</JobStatus>
      </CustomerRet>
      </CustomerQueryRs>
      <InvoiceQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
      <InvoiceRet>
      <TxnID>7-1274221220</TxnID>
      <TimeCreated>2010-05-18T15:20:20-08:00</TimeCreated>
      <TimeModified>2010-05-18T15:20:20-08:00</TimeModified>
      <EditSequence>1274221220</EditSequence>
      <TxnNumber>3</TxnNumber>
      <CustomerRef>
      <ListID>8000000E-1273520333</ListID>
      <FullName>Harold R2</FullName>
      </CustomerRef>
      <ARAccountRef>
      <ListID>80000008-1272911970</ListID>
      <FullName>Accounts Receivable</FullName>
      </ARAccountRef>
      <TemplateRef>
      <ListID>80000003-1271891691</ListID>
      <FullName>Intuit Service Invoice</FullName>
      </TemplateRef>
      <TxnDate>2010-05-18</TxnDate>
      <RefNumber>3</RefNumber>
      <BillAddress>
      <Addr1>Harold Donaldson</Addr1>
      </BillAddress>
      <BillAddressBlock>
      <Addr1>Harold Donaldson</Addr1>
      </BillAddressBlock>
      <IsPending>false</IsPending>
      <IsFinanceCharge>false</IsFinanceCharge>
      <DueDate>2010-05-18</DueDate>
      <ShipDate>2010-05-18</ShipDate>
      <Subtotal>10.00</Subtotal>
      <SalesTaxPercentage>0.00</SalesTaxPercentage>
      <SalesTaxTotal>0.00</SalesTaxTotal>
      <AppliedAmount>0.00</AppliedAmount>
      <BalanceRemaining>10.00</BalanceRemaining>
      <IsPaid>false</IsPaid>
      <IsToBePrinted>true</IsToBePrinted>
      <IsToBeEmailed>false</IsToBeEmailed>
        <InvoiceLineRet>
        <TxnLineID>9-1274221220</TxnLineID>
        <ItemRef>
          <ListID>80000002-1273542783</ListID>
          <FullName>Services Rendered</FullName>
        </ItemRef>
        <Quantity>1</Quantity>
        <Rate>10.00</Rate>
        <Amount>10.00</Amount>
        <SalesTaxCodeRef>
        <ListID>80000002-1271891691</ListID>
        <FullName>Non</FullName>
        </SalesTaxCodeRef>
        </InvoiceLineRet>
      </InvoiceRet>
      </InvoiceQueryRs>

      <ItemQueryRs requestID="2" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
      <ItemServiceRet>
      <ListID>80000002-1273542783</ListID>
      <TimeCreated>2010-05-10T18:53:03-08:00</TimeCreated>
      <TimeModified>2010-05-10T18:53:03-08:00</TimeModified>
      <EditSequence>1273542783</EditSequence>
      <Name>Awesome</Name>
      <FullName>Awesome</FullName>
      <IsActive>true</IsActive>
      <Sublevel>0</Sublevel>
      <SalesOrPurchase>
      <Price>0.00</Price>
      <AccountRef>
      <ListID>80000006-1271891701</ListID>
      <FullName>Payroll Expenses</FullName>
      </AccountRef>
      </SalesOrPurchase>
      </ItemServiceRet>
      </ItemQueryRs>

      </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_invoice_query_response
    %{
      <QBXML>
      <QBXMLMsgsRs>
      <InvoiceQueryRs statusCode="0" statusSeverity="Info" statusMessage="Status OK">
      <InvoiceRet>
      <TxnID>7-1274221220</TxnID>
      <TimeCreated>2010-05-18T15:20:20-08:00</TimeCreated>
      <TimeModified>2010-05-18T15:20:20-08:00</TimeModified>
      <EditSequence>1274221220</EditSequence>
      <TxnNumber>3</TxnNumber>
      <CustomerRef>
      <ListID>8000000E-1273520333</ListID>
      <FullName>Harold R2</FullName>
      </CustomerRef>
      <ARAccountRef>
      <ListID>80000008-1272911970</ListID>
      <FullName>Accounts Receivable</FullName>
      </ARAccountRef>
      <TemplateRef>
      <ListID>80000003-1271891691</ListID>
      <FullName>Intuit Service Invoice</FullName>
      </TemplateRef>
      <TxnDate>2010-05-18</TxnDate>
      <RefNumber>3</RefNumber>
      <BillAddress>
      <Addr1>Harold Donaldson</Addr1>
      </BillAddress>
      <BillAddressBlock>
      <Addr1>Harold Donaldson</Addr1>
      </BillAddressBlock>
      <IsPending>false</IsPending>
      <IsFinanceCharge>false</IsFinanceCharge>
      <DueDate>2010-05-18</DueDate>
      <ShipDate>2010-05-18</ShipDate>
      <Subtotal>10.00</Subtotal>
      <SalesTaxPercentage>0.00</SalesTaxPercentage>
      <SalesTaxTotal>0.00</SalesTaxTotal>
      <AppliedAmount>0.00</AppliedAmount>
      <BalanceRemaining>10.00</BalanceRemaining>
      <IsPaid>false</IsPaid>
      <IsToBePrinted>true</IsToBePrinted>
      <IsToBeEmailed>false</IsToBeEmailed>
      <InvoiceLineRet>
      <TxnLineID>9-1274221220</TxnLineID>
      <ItemRef>
      <ListID>80000002-1273542783</ListID>
      <FullName>Awesome</FullName>
      </ItemRef>
      <Quantity>1</Quantity>
      <Rate>10.00</Rate>
      <Amount>10.00</Amount>
      <SalesTaxCodeRef>
      <ListID>80000002-1271891691</ListID>
      <FullName>Non</FullName>
      </SalesTaxCodeRef>
      </InvoiceLineRet>
      </InvoiceRet>
      </InvoiceQueryRs>
      </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_customer_update_response
    %q{
      <QBXML>
      <QBXMLMsgsRs>
      <CustomerModRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
      <CustomerRet>
      <ListID>800000D6-1271805311</ListID>
      <TimeCreated>2009-03-12T13:21:04-08:00</TimeCreated>
      <TimeModified>2009-03-12T13:21:04-08:00</TimeModified>
      <EditSequence>1271811519</EditSequence>
      <Name>Foo Bar Spam</Name>
      <FullName>Foo Bar Spam</FullName>
      <IsActive>true</IsActive>
      <Sublevel>0</Sublevel>
      <Balance>0.00</Balance>
      <TotalBalance>0.00</TotalBalance>
      <JobStatus>None</JobStatus>
      </CustomerRet>
      </CustomerModRs>
      </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_customer_mod_response
    %q{
      <QBXML>
      <QBXMLMsgsRs>
      <CustomerModRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
      <CustomerRet>
      <ListID>80000001-1271891747</ListID>
      <TimeCreated>2010-04-21T16:15:47-08:00</TimeCreated>
      <TimeModified>2010-04-22T15:01:24-08:00</TimeModified>
      <EditSequence>1271973684</EditSequence>
      <Name>NAME NAME NAME</Name>
      <FullName>NAME NAME NAME</FullName>
      <IsActive>true</IsActive>
      <Sublevel>0</Sublevel>
      <Balance>0.00</Balance>
      <TotalBalance>0.00</TotalBalance>
      <JobStatus>None</JobStatus>
      </CustomerRet>
      </CustomerModRs>
      </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_invoice_add_response
    %q{
      <QBXML>
        <QBXMLMsgsRs>
          <InvoiceAddRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
            <InvoiceRet>
              <TxnID>xyz987</TxnID>
              <TimeCreated>2010-04-19T10:46:46-08:00</TimeCreated>
              <TimeModified>2010-04-19T10:46:46-08:00</TimeModified>
              <EditSequence>1271699206</EditSequence>
            </InvoiceRet>
          </InvoiceAddRs>
        </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_double_invoice_add_response
    %q{
      <QBXML>
        <QBXMLMsgsRs>
          <InvoiceAddRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
            <InvoiceRet>
              <TxnID>xyz987</TxnID>
              <TimeCreated>2010-04-19T10:46:46-08:00</TimeCreated>
              <TimeModified>2010-04-19T10:46:46-08:00</TimeModified>
              <EditSequence>1271699206</EditSequence>
            </InvoiceRet>
          </InvoiceAddRs>
          <InvoiceAddRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
            <InvoiceRet>
              <TxnID>600000D9-5374119874</TxnID>
              <TimeCreated>2010-04-19T10:46:46-08:00</TimeCreated>
              <TimeModified>2010-04-19T10:46:46-08:00</TimeModified>
              <EditSequence>1271699206</EditSequence>
            </InvoiceRet>
          </InvoiceAddRs>
        </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_customer_delete_response
    "<QBXML>\n<QBXMLMsgsRs>\n<ListDelRs requestID=\"0\" statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\">\n<ListDelType>Customer</ListDelType>\n<ListID>80000003-1271969969</ListID>\n<TimeDeleted>2010-05-06T17:46:31-08:00</TimeDeleted>\n<FullName>Customer remote</FullName>\n</ListDelRs>\n</QBXMLMsgsRs>\n</QBXML>\n"
  end

  def error_response
    "<QBXML>\n<QBXMLMsgsRs>\n<CustomerModRs requestID=\"0\" statusCode=\"3200\" statusSeverity=\"Error\" statusMessage=\"The provided edit sequence &quot;1272664823&quot; is out-of-date. \">\n<CustomerRet>\n<ListID>80000003-1271969969</ListID>\n<TimeCreated>2010-04-22T13:59:29-08:00</TimeCreated>\n<TimeModified>2010-04-30T15:08:47-08:00</TimeModified>\n<EditSequence>1272665327</EditSequence>\n<Name>John Hancock qb</Name>\n<FullName>John Hancock qb</FullName>\n<IsActive>true</IsActive>\n<Sublevel>0</Sublevel>\n<BillAddress>\n<Addr1>2124 SE Belmont</Addr1>\n<City>Portland</City>\n<State>OR</State>\n<PostalCode>97214</PostalCode>\n</BillAddress>\n<BillAddressBlock>\n<Addr1>2124 SE Belmont</Addr1>\n<Addr2>Portland, OR 97214</Addr2>\n</BillAddressBlock>\n<Balance>0.00</Balance>\n<TotalBalance>0.00</TotalBalance>\n<JobStatus>Awarded</JobStatus>\n</CustomerRet>\n</CustomerModRs>\n</QBXMLMsgsRs>\n</QBXML>\n"
  end

  def warning_response
    "<QBXML>\n<QBXMLMsgsRs>\n<CustomerModRs requestID=\"0\" statusCode=\"530\" statusSeverity=\"Warn\" statusMessage=\"The field &quot;IsStatementWithParent&quot; is not supported by this implementation.\">\n<CustomerRet>\n<ListID>80000003-1271969969</ListID>\n<TimeCreated>2010-04-22T13:59:29-08:00</TimeCreated>\n<TimeModified>2010-04-30T16:24:51-08:00</TimeModified>\n<EditSequence>1272669891</EditSequence>\n<Name>John Hancock</Name>\n<FullName>John Hancock</FullName>\n<IsActive>true</IsActive>\n<Sublevel>0</Sublevel>\n<BillAddress>\n<Addr1>2124 SE Belmont</Addr1>\n<City>Portland</City>\n<State>OR</State>\n<PostalCode>97214</PostalCode>\n</BillAddress>\n<BillAddressBlock>\n<Addr1>2124 SE Belmont</Addr1>\n<Addr2>Portland, OR 97214</Addr2>\n</BillAddressBlock>\n<Balance>0.00</Balance>\n<TotalBalance>0.00</TotalBalance>\n<JobStatus>Awarded</JobStatus>\n</CustomerRet>\n</CustomerModRs>\n</QBXMLMsgsRs>\n</QBXML>\n"
  end

  def valid_item_query_response
    %q{<QBXML>
    <QBXMLMsgsRs>
    <ItemQueryRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
    <ItemServiceRet>
    <ListID>80000002-1273542783</ListID>
    <TimeCreated>2010-05-10T18:53:03-08:00</TimeCreated>
    <TimeModified>2010-05-10T18:53:03-08:00</TimeModified>
    <EditSequence>1273542783</EditSequence>
    <Name>Awesome</Name>
    <FullName>Awesome</FullName>
    <IsActive>true</IsActive>
    <Sublevel>0</Sublevel>
    <SalesOrPurchase>
    <Price>0.00</Price>
    <AccountRef>
    <ListID>80000006-1271891701</ListID>
    <FullName>Payroll Expenses</FullName>
    </AccountRef>
    </SalesOrPurchase>
    </ItemServiceRet>
    </ItemQueryRs>
    </QBXMLMsgsRs>
    </QBXML>}
  end

  def valid_first_page_response
    %q{
      <QBXML>
        <QBXMLMsgsRs>
          <CustomerQueryRs requestID="1" statusCode="0" statusSeverity="Info" statusMessage="Status OK" iteratorRemainingCount="1" iteratorID="{6b474085-9943-46e2-ad71-d0a5aba9e948}">
            <CustomerRet>
              <ListID>40000-1236889264</ListID>
              <TimeCreated>2009-03-12T13:21:04-08:00</TimeCreated>
              <TimeModified>2009-03-12T13:21:47-08:00</TimeModified>
              <EditSequence>1236889307</EditSequence>
              <Name>Builder's Supply LLC</Name>
              <FullName>Builder's Supply LLC</FullName>
              <IsActive>true</IsActive>
              <Sublevel>0</Sublevel>
              <BillAddress>
                <Addr1>Builder's Supply LLC</Addr1>
              </BillAddress>
              <BillAddressBlock>
                <Addr1>Builder's Supply LLC</Addr1>
              </BillAddressBlock>
              <TermsRef>
                <ListID>10000-1236889119</ListID>
                <FullName>Net 10</FullName>
              </TermsRef>
              <Balance>2334.00</Balance>
              <TotalBalance>2334.00</TotalBalance>
              <SalesTaxCodeRef>
                <ListID>20000-1229303705</ListID>
                <FullName>Non</FullName>
              </SalesTaxCodeRef>
              <JobStatus>None</JobStatus>
            </CustomerRet>
          </CustomerQueryRs>

          <InvoiceQueryRs requestID="2" statusCode="0" statusSeverity="Info" statusMessage="Status OK" iteratorRemainingCount="0">
          <InvoiceRet>
          <TxnID>7-1274221220</TxnID>
          <TimeCreated>2010-05-18T15:20:20-08:00</TimeCreated>
          <TimeModified>2010-05-18T15:20:20-08:00</TimeModified>
          <EditSequence>1274221220</EditSequence>
          <TxnNumber>3</TxnNumber>
          <CustomerRef>
          <ListID>8000000E-1273520333</ListID>
          <FullName>Harold R2</FullName>
          </CustomerRef>
          <ARAccountRef>
          <ListID>80000008-1272911970</ListID>
          <FullName>Accounts Receivable</FullName>
          </ARAccountRef>
          <TemplateRef>
          <ListID>80000003-1271891691</ListID>
          <FullName>Intuit Service Invoice</FullName>
          </TemplateRef>
          <TxnDate>2010-05-18</TxnDate>
          <RefNumber>3</RefNumber>
          <BillAddress>
          <Addr1>Harold Donaldson</Addr1>
          </BillAddress>
          <BillAddressBlock>
          <Addr1>Harold Donaldson</Addr1>
          </BillAddressBlock>
          <IsPending>false</IsPending>
          <IsFinanceCharge>false</IsFinanceCharge>
          <DueDate>2010-05-18</DueDate>
          <ShipDate>2010-05-18</ShipDate>
          <Subtotal>10.00</Subtotal>
          <SalesTaxPercentage>0.00</SalesTaxPercentage>
          <SalesTaxTotal>0.00</SalesTaxTotal>
          <AppliedAmount>0.00</AppliedAmount>
          <BalanceRemaining>10.00</BalanceRemaining>
          <IsPaid>false</IsPaid>
          <IsToBePrinted>true</IsToBePrinted>
          <IsToBeEmailed>false</IsToBeEmailed>
            <InvoiceLineRet>
            <TxnLineID>9-1274221220</TxnLineID>
            <ItemRef>
              <ListID>80000002-1273542783</ListID>
              <FullName>Services Rendered</FullName>
            </ItemRef>
            <Quantity>1</Quantity>
            <Rate>10.00</Rate>
            <Amount>10.00</Amount>
            <SalesTaxCodeRef>
            <ListID>80000002-1271891691</ListID>
            <FullName>Non</FullName>
            </SalesTaxCodeRef>
            </InvoiceLineRet>
          </InvoiceRet>
          </InvoiceQueryRs>

        </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_second_page_request
    %q{
      <QBXML>
         <QBXMLMsgsRq onError="stopOnError">
            <CustomerQueryRq requestID="0" iterator="Continue" iteratorID="{6b474085-9943-46e2-ad71-d0a5aba9e948}">
               <MaxReturned>500</MaxReturned>
            </CustomerQueryRq>
         </QBXMLMsgsRq>
      </QBXML>
    }
  end

  def valid_last_page_response
    %q{
      <QBXML>
        <QBXMLMsgsRs>
          <CustomerQueryRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK" iteratorRemainingCount="0" iteratorID="{6b474085-9943-46e2-ad71-d0a5aba9e948}">
            <CustomerRet>
              <ListID>xyz987</ListID>
              <TimeCreated>2009-03-12T13:21:04-08:00</TimeCreated>
              <TimeModified>2009-03-12T13:21:47-08:00</TimeModified>
              <EditSequence>1236889307</EditSequence>
              <Name>Builder's Supply LLC</Name>
              <FullName>Builder's Supply LLC</FullName>
              <IsActive>true</IsActive>
              <Sublevel>0</Sublevel>
              <BillAddress>
                <Addr1>Builder's Supply LLC</Addr1>
              </BillAddress>
              <BillAddressBlock>
                <Addr1>Builder's Supply LLC</Addr1>
              </BillAddressBlock>
              <TermsRef>
                <ListID>10000-1236889119</ListID>
                <FullName>Net 10</FullName>
              </TermsRef>
              <Balance>2334.00</Balance>
              <TotalBalance>2334.00</TotalBalance>
              <SalesTaxCodeRef>
                <ListID>20000-1229303705</ListID>
                <FullName>Non</FullName>
              </SalesTaxCodeRef>
              <JobStatus>None</JobStatus>
            </CustomerRet>
          </CustomerQueryRs>

        </QBXMLMsgsRs>
      </QBXML>

    }
  end

  def valid_payment_add_request
    %q(
    <QBXML>
      <QBXMLMsgsRq onError="continueOnError">
        <ReceivePaymentAddRq requestID="0">
          <ReceivePaymentAdd>
            <CustomerRef>
              <ListID>abc123</ListID>
            </CustomerRef>
            <TotalAmount>123.45</TotalAmount>
            <PaymentMethodRef>
              <ListID>foo999</ListID>
            </PaymentMethodRef>
            <AppliedToTxnAdd>
              <TxnID>xyz987</TxnID>
              <PaymentAmount>123.45</PaymentAmount>
            </AppliedToTxnAdd>
          </ReceivePaymentAdd>
        </ReceivePaymentAddRq>
      </QBXMLMsgsRq>
    </QBXML>
    )
  end

  def valid_payment_add_response
    %q{
      <QBXML>
        <QBXMLMsgsRs>
          <ReceivePaymentAddRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
            <ReceivePaymentRet>
              <TxnId>xyz987</TxnId>
              <TimeCreated>2010-04-19T10:46:46-08:00</TimeCreated>
              <TimeModified>2010-04-19T10:46:46-08:00</TimeModified>
              <EditSequence>1271699206</EditSequence>
            </ReceivePaymentRet>
          </ReceivePaymentAddRs>
        </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_credit_memo_add_request
    %q{
      <QBXML>
         <QBXMLMsgsRq onError="continueOnError">
            <CreditMemoAddRq requestID="0">
               <CreditMemoAdd>
                  <CustomerRef>
                     <ListID>abc123</ListID>
                  </CustomerRef>
                  <CreditMemoLineAdd>
                     <ItemRef>
                        <ListID>foobar</ListID>
                     </ItemRef>
                     <Quantity>1</Quantity>
                     <Rate>50.00</Rate>
                  </CreditMemoLineAdd>
               </CreditMemoAdd>
            </CreditMemoAddRq>
         </QBXMLMsgsRq>
      </QBXML>
    }
  end

  def valid_credit_memo_add_response
    %q{
      <QBXML>
      <QBXMLMsgsRs>
      <CreditMemoAddRs requestID="0" statusCode="0" statusSeverity="Info" statusMessage="Status OK">
      <CreditMemoRet>
      <TxnID>91-1283386643</TxnID>
      <TimeCreated>2010-09-01T17:17:23-08:00</TimeCreated>
      <TimeModified>2010-09-01T17:17:23-08:00</TimeModified>
      <EditSequence>1283386643</EditSequence>
      <TxnNumber>32</TxnNumber>
      <CustomerRef>
      <ListID>8000000B-1282098265</ListID>
      <FullName>N7 - Prospective Domestic</FullName>
      </CustomerRef>
      <ARAccountRef>
      <ListID>80000034-1282098558</ListID>
      <FullName>Accounts Receivable</FullName>
      </ARAccountRef>
      <TemplateRef>
      <ListID>8000000C-1283386551</ListID>
      <FullName>Custom Credit Memo</FullName>
      </TemplateRef>
      <TxnDate>2010-09-01</TxnDate>
      <RefNumber>20</RefNumber>
      <IsPending>false</IsPending>
      <DueDate>2010-09-01</DueDate>
      <ShipDate>2010-09-01</ShipDate>
      <Subtotal>50.00</Subtotal>
      <SalesTaxPercentage>0.00</SalesTaxPercentage>
      <SalesTaxTotal>0.00</SalesTaxTotal>
      <TotalAmount>50.00</TotalAmount>
      <CreditRemaining>50.00</CreditRemaining>
      <IsToBePrinted>true</IsToBePrinted>
      <IsToBeEmailed>false</IsToBeEmailed>
      <CreditMemoLineRet>
      <TxnLineID>93-1283386643</TxnLineID>
      <ItemRef>
      <ListID>80000001-1282098685</ListID>
      <FullName>Admission fee</FullName>
      </ItemRef>
      <Quantity>1</Quantity>
      <Rate>50.00</Rate>
      <Amount>50.00</Amount>
      <SalesTaxCodeRef>
      <ListID>80000002-1282092928</ListID>
      <FullName>Non</FullName>
      </SalesTaxCodeRef>
      </CreditMemoLineRet>
      </CreditMemoRet>
      </CreditMemoAddRs>
      </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def valid_refund_add_request
    %q{<QBXML>
         <QBXMLMsgsRq onError="stopOnError">
            <ARRefundCreditCardAddRq requestID="0">
               <ARRefundCreditCardAdd>
                  <CustomerRef>
                     <ListID>abc123</ListID>
                  </CustomerRef>
                  <RefundAppliedToTxnAdd>
                     <TxnID>cm1</TxnID>
                     <RefundAmount>50.00</RefundAmount>
                  </RefundAppliedToTxnAdd>
               </ARRefundCreditCardAdd>
            </ARRefundCreditCardAddRq>
         </QBXMLMsgsRq>
      </QBXML>}
  end

  def valid_refund_add_response
    ""
  end

  def customer_add_error_response
    %q{
    <QBXML>
    <QBXMLMsgsRs>
    <CustomerAddRs requestID="0" statusCode="3100" statusSeverity="Error" statusMessage="The name &quot;abc&quot; of the list element is already in use."/>
    </QBXMLMsgsRs>
    </QBXML>
    }
  end

  def customer_update_error_response
    %q{
      <QBXML>
      <QBXMLMsgsRs>
      <CustomerModRs requestID="0" statusCode="3100" statusSeverity="Error" statusMessage="The name &quot;Anal Retentive&quot; is already taken." />
      </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def error_customer_query_response
    %q{
      <QBXML>
      <QBXMLMsgsRs>
          <CustomerQueryRs requestID="0" statusCode="911" statusSeverity="Error" statusMessage="I am a terrible program and need to die" />
      </QBXMLMsgsRs>
      </QBXML>
    }
  end

  def batch_customer_add_error_response
    "<?xml version=\"1.0\" ?>\n<QBXML>\n<QBXMLMsgsRs>\n<CustomerAddRs requestID=\"0\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;10303464 - siva kumar nakshatrala&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"1\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161012 - Rajbir Bajwa&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"2\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;10303465 - deepak muthyalu&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"3\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161013 - Venkata Kalyan Gadde&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"4\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161015 - Kalyan Chakravarthi Cherukuri&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"5\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161016 - Vinay Kumar Chittiboyina&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"6\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161017 - syeda quader&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"7\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161018 - PRASHANTH BADHA&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"8\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161019 - vinisha taniparthi&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"9\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161020 - suneeta Bitta&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"10\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161021 - venkatesh suhas&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"11\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161022 - Bala Krishna Chitteti&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"12\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161023 - Jasmine  desai&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"13\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161024 - yugendhar rao munagala&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"14\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161025 - Surya Narayana Suresh Yenamand&quot; of the list element is already in use.\" />\n<CustomerAddRs requestID=\"15\" statusCode=\"3100\" statusSeverity=\"Error\" statusMessage=\"The name &quot;11161026 - bhavani kurapati&quot; of the list element is already in use.\" />\n</QBXMLMsgsRs>\n</QBXML>\n"
  end

end
