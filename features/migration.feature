@migration
Feature: Instance migration
  As administrator
  I want to make sure that Instance migration is working correctly

  Background:
    Given At least 2 Compute nodes must be enabled
    And Image is available

  @kvm
  Scenario: Test KVM migration
    Given At least 2 nodes with KVM Hypervisors
    When I create an KVM instance
    And Instance is running
    And I migrate KVM instance
    Then I expect the instance will run on different host
    And will be in state "ACTIVE"
    And I turn off the instance to save resources

  @xen
  Scenario: Test Xen migration
    Given At least 2 Xen Hypervisors are available
    When I create an Xen instance
    And Instance is running
    And I migrate Xen instance
    Then I expect the instance will run on different host
    And will be in state "ACTIVE"
    And I turn off the instance to save resources
