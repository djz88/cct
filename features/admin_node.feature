Feature: Admin node
  As a cloud administrator
  I want to validate the admin node installation and configuration
  In order to make sure the node management is all set

  Background:
    Given the admin node responds to a ping
    And I can establish SSH connection
    And I can reach the crowbar API

  @os
  Scenario: Operating system support
    Given the admin node is running "SUSE Linux Enterprise Server 11"
    And the following packages are installed:
      | Package name                         |
      | suse-cloud-release                   |
      | crowbar-barclamp-ceilometer          |
      | crowbar-barclamp-ceph                |
      | crowbar-barclamp-cinder              |
      | crowbar-barclamp-cisco-ucs           |
      | crowbar-barclamp-crowbar             |
      | crowbar-barclamp-database            |
      | crowbar-barclamp-deployer            |
      | crowbar-barclamp-dns                 |
      | crowbar-barclamp-glance              |
      | crowbar-barclamp-heat                |
      | crowbar-barclamp-hyperv              |
      | crowbar-barclamp-hyperv-data         |
      | crowbar-barclamp-ipmi                |
      | crowbar-barclamp-keystone            |
      | crowbar-barclamp-logging             |
      | crowbar-barclamp-network             |
      | crowbar-barclamp-neutron             |
      | crowbar-barclamp-nfs_client          |
      | crowbar-barclamp-nova                |
      | crowbar-barclamp-nova_dashboard      |
      | crowbar-barclamp-ntp                 |
      | crowbar-barclamp-openstack           |
      | crowbar-barclamp-pacemaker           |
      | crowbar-barclamp-provisioner         |
      | crowbar-barclamp-rabbitmq            |
      | crowbar-barclamp-suse-manager-client |
      | crowbar-barclamp-swift               |
      | crowbar-barclamp-tempest             |
      | crowbar-barclamp-trove               |
      | crowbar-barclamp-updater             |
    Then I verify the admin node is in "ready" state

  @ntp
  Scenario: NTP Server availability
    Given the NTP Server is running
    When I request server for estimated correct local date and time
    Then I receive a response within the "5" seconds timeout

  @packages
  Scenario: Essential packages installed

  @services
  Scenario: Essential services enabled and active
