Feature: Synchronizing two QuickBooks repositories

  Scenario: One customer record in QuickBooks and no records on the sync server
    Given there is a QuickBooks instance running with the following resources:
      |type     |name |
      |Customer |Bob  |
    And there is a sync server running with no resources 
    When I synchronize my local QuickBooks data to the sync server
    Then QuickBooks should have the following resources:
      |type    |name |
      |Customer|Bob  |
    And the sync server should have the following resources:
      |type    |name |
      |Customer|Bob  |

  Scenario: No records in QuickBooks and one customer record on the sync server
    Given there is a QuickBooks instance running with no resources
    And there is a sync server running with the following resources:
      |type     |name |
      |Customer |Bob  |
    When I synchronize my local QuickBooks data to the sync server
    Then QuickBooks should have the following resources:
      |type    |name |
      |Customer|Bob  |
    And the sync server should have the following resources:
      |type    |name |
      |Customer|Bob  |

  Scenario: One customer record in QuickBooks and an outdated version of the same record on the sync server
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |updated_at|
      |Customer |abc123 |Steve|1/2/2010   |
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |updated_at|
      |Customer |abc123 |Bob  |1/1/2010   |
    When I synchronize my local QuickBooks data to the sync server
    Then QuickBooks should have the following resources:
      |type     |quick_books_id|name |updated_at|
      |Customer |abc123 |Steve|1/2/2010   |
    And the sync server should have the following resources:
      |type     |quick_books_id|name |updated_at|
      |Customer |abc123 |Steve|1/2/2010   |

  Scenario: One outdated version of different resources on each repository
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |updated_at|
      |Customer |abc123 |Ed   |1/1/2010   |
      |Customer |def456 |Dave |12/12/2009 |
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |updated_at|
      |Customer |abc123 |Bob  |12/1/2009  |
      |Customer |def456 |John |1/1/2010   |
    When I synchronize my local QuickBooks data to the sync server
    Then QuickBooks should have the following resources:
      |type     |quick_books_id|name |updated_at|
      |Customer |abc123 |Ed   |1/1/2010   |
      |Customer |def456 |John |1/1/2010   |
    And the sync server should have the following resources:
      |type     |quick_books_id|name |updated_at|
      |Customer |abc123 |Ed   |1/1/2010   |
      |Customer |def456 |John |1/1/2010   |

  Scenario: One outdated resource on each server, each with different modified fields, and mismatched vector clocks
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |def456 |Steve|25 |12/12/2009 |2      |
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |def456 |Dave |24 |12/13/2009 |1      |
    And I have changed all the remote resources since syncing them
    When I synchronize my local QuickBooks data to the sync server
    Then there should be 1 merge conflict

  Scenario: One outdated resource on each server, one up-to-date resource, and mismatched vector clocks
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |1|
      |Customer |def456 |Steve|25 |12/12/2009 |2|
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |1|
      |Customer |def456 |Dave |24 |12/13/2009 |1|
    And I have changed all the remote resources since syncing them
    When I synchronize my local QuickBooks data to the sync server
    Then there should be 1 merge conflict

  Scenario: Two outdated resources on each server, one only modified on QuickBooks, and mismatched vector clocks
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |2           |
      |Customer |def456 |Steve|25 |12/12/2009 |1           |
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Jimmy|25 |12/13/2009 |1           |
      |Customer |def456 |Dave |24 |12/13/2009 |1           |
    And I have changed all the remote resources since syncing them
    When I synchronize my local QuickBooks data to the sync server
    Then there should be 1 merge conflict

  Scenario: Deleting one resource on QuickBooks and synchronizing
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |2           |
      |Customer |def456 |Steve|25 |12/12/2009 |1           |
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |2           |
      |Customer |def456 |Steve|25 |12/12/2009 |1           |
    When I delete the following record from QuickBooks: 
      |type     |quick_books_id|name |
      |Customer |abc123 |Timmy|
    And I synchronize my local QuickBooks data to the sync server
    Then QuickBooks should have the following resources:
      |type     |quick_books_id|name |
      |Customer |def456 |Steve|
    And the sync server should have the following resources:
      |type     |quick_books_id|name |
      |Customer |def456 |Steve|
  

  Scenario: One outdated resource on each server, one up-to-date resource, and mismatched vector clocks
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |1|
      |Customer |def456 |Steve|25 |12/12/2009 |2|
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |1|
      |Customer |def456 |Dave |24 |12/13/2009 |1|
    And I have changed all the remote resources since syncing them
    When I synchronize my local QuickBooks data to the sync server
    Then there should be 1 merge conflict

  Scenario: Two outdated resources on each server, one only modified on QuickBooks, and mismatched vector clocks
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |2           |
      |Customer |def456 |Steve|25 |12/12/2009 |1           |
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Jimmy|25 |12/13/2009 |1           |
      |Customer |def456 |Dave |24 |12/13/2009 |1           |
    And I have changed all the remote resources since syncing them
    When I synchronize my local QuickBooks data to the sync server
    Then there should be 1 merge conflict

  Scenario: Deleting one resource on QuickBooks and synchronizing
    Given there is a QuickBooks instance running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |2           |
      |Customer |def456 |Steve|25 |12/12/2009 |1           |
    And there is a sync server running with the following resources:
      |type     |quick_books_id|name |age|updated_at|vector_clock|
      |Customer |abc123 |Timmy|25 |12/10/2009 |2           |
      |Customer |def456 |Steve|25 |12/12/2009 |1           |
    When I delete the following record from QuickBooks: 
      |type     |quick_books_id|name |
      |Customer |abc123 |Timmy|
    And I synchronize my local QuickBooks data to the sync server
    Then QuickBooks should have the following resources:
      |type     |quick_books_id|name |
      |Customer |def456 |Steve|
    And the sync server should have the following resources:
      |type     |quick_books_id|name |
      |Customer |def456 |Steve|
  
