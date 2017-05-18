@migration
Feature: Instance migration
  As administrator
  I want to make sure that Instance migration is working correctly

  Background:
    Given At least 2 Compute nodes must be enabled
    And Image is available

  @kvm
  Scenario: Test KVM migration
    Given At least 2 KVM Hypervisors are available
    When I create an KVM instance
    And Instance is running
    And I migrate KVM instance
    Then I expect the instance will run on different host
    And will be in state "ACTIVE"
    And I turn off the instance(so it will not use resources)

  @xen
  Scenario: Test Xen migrationnd I turn off the instance(so it will not use resources)
    Given At least 2 Xen Hypervisors are available
    When I create an Xen instance
    And Instance is running
    And I migrate Xen instance
    Then I expect the instance will run on different host
    And will be in state "ACTIVE"
    And I turn off the instance(so it will not use resources)
