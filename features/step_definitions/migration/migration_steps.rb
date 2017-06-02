Given(/^At least (\d+) nodes with Xen Hypervisors$/) do |number_of_nodes|
  # get hypervisors and count Xen's ones - for migration at least 2
  @hypervisors = control_node.openstack.hypervisor.list
  expect(@hypervisors).not_to be_empty

  xen_nodes = @hypervisors.select do |hv|
	  control_node.openstack.hypervisor.show(hv.id).hypervisor_type == "Xen"
  end
  expect(xen_nodes.size).to be >= number_of_nodes.to_i
end

Given(/^At least (\d+) nodes with KVM Hypervisors$/) do |number_of_nodes|
  # get hypervisors and count KVM's ones - for migration at least 2
  @hypervisors = control_node.openstack.hypervisor.list
  expect(@hypervisors).not_to be_empty

  kvm_nodes = @hypervisors.select do |hv|
	  control_node.openstack.hypervisor.show(hv.id).hypervisor_type == "QEMU"
  end
  expect(kvm_nodes.size).to be >= number_of_nodes.to_i
end

When(/^I create an KVM instance$/) do
  # clean old instances
  @servers = control_node.openstack.server.list
  @instance_name = "kvm_mig_instance"
  @servers.each do |s|
    s.name == @instance_name and delete_old_instances!(s.id)
  end
  # create a new instance
  command = "openstack server create -f value " +
			"--flavor m1.smaller --image jeos " +
			"--security-group default -c id #{@instance_name}"
  @new_instance = control_node.exec!(command)
  puts ("New instance id: #{@new_instance}")
end

When(/^I create an Xen instance$/) do
  # clean old instances
  @servers = control_node.openstack.server.list
  @instance_name = "xen_mig_instance"
  @servers.each do |s|
    s.name == @instance_name and delete_old_instances!(s.id)
  end
  # create a new instance
  command = "openstack server create -f value " +
			"--flavor m1.smaller --image jeos " +
			"--security-group default -c id #{@instance_name}"
  @new_instance = control_node.exec!(command)
  puts ("New instance id: #{@new_instance}")
end

When(/^Instance is running$/) do
  ## TODO Raise an expection if in ERROR state
  # it may take some time before the instance turns active
  wait_for "Checking that instance status is active", max: "120 seconds", sleep: "4 seconds" do
    @instance_show = control_node.openstack.server.show(@new_instance)
    break if @instance_show.status == "ACTIVE"
  end
end

When(/^I migrate Xen instance$/) do
  # get actual host of the instance and migrate it
  @instance_host = @instance_show.send("os-ext-srv-attr:host")
  puts "Instance running on: #{@instance_host}"
  instance_migrate = control_node.exec!("openstack server migrate --shared-migration #{@new_instance}")

  # it may take some time before the instance turns verify_resize
  wait_for "Checking that instance status is verify_resize", max: "300 seconds", sleep: "10 seconds" do
    instance_show = control_node.openstack.server.show(@new_instance)
    if instance_show.status == "VERIFY_RESIZE"
      puts "Migration finished, confirming..."
      control_node.exec!("openstack server resize --confirm #{@new_instance}")
    break
    end
  end
end

When(/^I migrate KVM instance$/) do
  # get actual host of the instance and migrate it
  @instance_host = @instance_show.send("os-ext-srv-attr:host")
  puts "Instance running on: #{@instance_host}"
  instance_migrate = control_node.exec!("openstack server migrate #{@new_instance}")

  # it may take some time before the instance turns verify_resize
  wait_for "Checking that instance status is verify_resize", max: "300 seconds", sleep: "10 seconds" do
    instance_show = control_node.openstack.server.show(@new_instance)
    if instance_show.status == "VERIFY_RESIZE"
      puts "Migration finished, confirming..."
      control_node.exec!("openstack server resize --confirm #{@new_instance}")
    break
    end
  end
end

Then(/^I expect the instance will run on different host$/) do
  instance_show = control_node.openstack.server.show(@new_instance)
  instance_host = instance_show.send("os-ext-srv-attr:host")
  puts "Instance running on: #{instance_host}"
  expect(@instance_host).not_to eq(instance_host)

end

Then(/^will be in state "([^"]*)"$/) do |arg1|
  wait_for "Checking that instance status is ACTIVE", max: "40 seconds", sleep: "10 seconds" do
    instance_show = control_node.openstack.server.show(@new_instance)
    break if instance_show.status == "ACTIVE"
  end
end

Then(/^I turn off the instance to save resources$/) do
  control_node.exec!("openstack server stop #{@new_instance}")
  wait_for "Checking that instance status is SHUTOFF", max: "120 seconds", sleep: "10 seconds" do
    instance_show = control_node.openstack.server.show(@new_instance)
    break if instance_show.status == "SHUTOFF"
  end
end

