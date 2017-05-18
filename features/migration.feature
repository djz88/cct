@xen
Feature: Instance migration
  As administrator
  I want to make sure that Instance migration is working correctly

  @xen
  Scenario: Test Xen migration
    Given Hypervisors are available
    And Xen compute nodes are available
    And Image is available
    When I create an instance
    And Instance is running
    And I migrate instance
    Then I expect the instance will run on different host
    And will be in state "ACTIVE"
