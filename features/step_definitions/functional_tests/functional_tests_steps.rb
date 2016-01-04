Given(/^the test package "([^"]*)" is installed on the controller node$/) do |test_package|
  control_node.rpm_q(test_package)
end

Given(/^the package "([^"]*)" is installed on the controller node$/) do |client_package|
  control_node.rpm_q(client_package)
end

Given(/^the proper cirros test image has been created$/) do
  test_image_name = "cirros-test-image-uec"

  if control_node.openstack.image.list.find {|img| img.name == test_image_name }
    control_node.openstack.image.delete(test_image_name)
  end

  @test_image = control_node.openstack.image.create(
    test_image_name,
    copy_from: "http://clouddata.nue.suse.com/images/cirros-0.3.4-x86_64-disk.img",
    container_format: :bare,
    disk_format: :qcow2,
    public: true
  )

  wait_for "Image status set 'active'", max: "60 seconds", sleep: "2 seconds" do
    image = control_node.openstack.image.show(@test_image.id)
    break if image.status == "active"
  end
end

Then(/^all the functional tests for the package "([^"]*)" pass$/) do |package_name|
  tests_dir = "/var/lib/#{package_name}-test"
  package_core_name = package_name.match(/python-(.+)/).captures.first
  ssl_insecure =
    case package_name
    when "python-novaclient"
      json_response = JSON.parse(admin_node.exec!("crowbar nova show default").output)
      json_response["attributes"]["nova"]["ssl"]["insecure"]
    end
  env = {
    "OS_NOVACLIENT_EXEC_DIR" => "/usr/bin",
    "OS_TEST_PATH" => "#{package_core_name}/tests/functional"
  }
  env["OS_INSECURE"] = "true" if ssl_insecure
  tests_to_run = "tests_to_run"
  excluded_tests =
    case package_name
    when "python-novaclient"
      [
        "test_admin_dns_domains", # Does not work with neutron
        "test_fixedip_get",       # This uses nova-network specific API
        # FIXME: The following tests can be re-enabled once:
        # https://bugs.launchpad.net/python-novaclient/+bug/1510975
        # is fixed.
        "test_server_ips",        # Relies on the default network called "private"
        "test_instances",         # Requires the "first" network returned to be
        "test_servers"            # non-external
      ]
    end

  # filter out the excluded tests into a file first
  control_node.exec!(
    "cd #{tests_dir};
    testr list-tests | grep -v '#{excluded_tests.join('\|')}\' > #{tests_to_run}",
    env
  )

  # run the tests finally
  control_node.exec!(
    "cd #{tests_dir}; python setup.py testr --testr-args '--load-list #{tests_to_run}'",
    env
  )
end
