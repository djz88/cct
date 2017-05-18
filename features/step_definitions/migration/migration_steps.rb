Given(/^At least (\d+) Xen Hypervisors are available$/) do |arg1|
  # get hypervisors and count Xen's ones - for migration at least 2
  hashypervisor_xen = 0
  @hypervisors = control_node.openstack.hypervisor.list
  expect(@hypervisors).not_to be_empty

  @hypervisors.each do |h|
    hypervisor = control_node.openstack.hypervisor.show(h.id)
    hashypervisor_xen = (hashypervisor_xen + 1) if hypervisor.hypervisor_type == "Xen"
  end
  expect(hashypervisor_xen).to be >= arg1.to_i
end

Given(/^At least (\d+) KVM Hypervisors are available$/) do |arg1|
  # get hypervisors and count KVM's ones - for migration at least 2
  hashypervisor_kvm = 0
  @hypervisors = control_node.openstack.hypervisor.list
  expect(@hypervisors).not_to be_empty

  @hypervisors.each do |h|
    hypervisor = control_node.openstack.hypervisor.show(h.id)
    hashypervisor_kvm = (hashypervisor_kvm + 1) if hypervisor.hypervisor_type == "QEMU"
  end
  expect(hashypervisor_kvm).to be >= arg1.to_i
end

When(/^I create an KVM instance$/) do
  def delete_old_instances(server_id)
    puts("old instance #{server_id } found - deleting")
    control_node.exec!("openstack server delete #{server_id}")
  end
  ## TODO add --key-name zkubala
  # clean old instances
  @servers = control_node.openstack.server.list
  @instance_name = "kvm_mig_instance"
  @servers.each do |s|
    s.name == @instance_name and delete_old_instances(s.id)
  end
  # create a new instance
  new_instance = control_node.exec!("openstack server create -f shell --flavor m1.smaller --image jeos --security-group default -c id #{@instance_name}")
  @new_instance_id = new_instance.output[4, 36]
  puts ("New instance id: #{@new_instance_id}")
end

When(/^I create an Xen instance$/) do
  def delete_old_instances(server_id)
    puts("old instance #{server_id } found - deleting")
    control_node.exec!("openstack server delete #{server_id}")
  end
  ## TODO add --key-name zkubala
  # clean old instances
  @servers = control_node.openstack.server.list
  @instance_name = "xen_mig_instance"
  @servers.each do |s|
    s.name == @instance_name and delete_old_instances(s.id)
  end
  # create a new instance
  new_instance = control_node.exec!("openstack server create -f shell --flavor m1.smaller --image jeos --security-group default -c id #{@instance_name}")
  @new_instance_id = new_instance.output[4, 36]
  puts ("New instance id: #{@new_instance_id}")
end

When(/^Instance is running$/) do
  ## TODO Raise an expection if in ERROR state 
  # it may take some time before the instance turns active
  wait_for "Checking that instance status is active", max: "120 seconds", sleep: "4 seconds" do
    @instance_show = control_node.openstack.server.show(@new_instance_id)
    break if @instance_show.status == "ACTIVE"
  end
end

When(/^I migrate Xen instance$/) do
  # get actual host of the instance and migrate it
  @instance_host = @instance_show.send("os-ext-srv-attr:host")
  puts "Instance running on: #{@instance_host}"
  instance_migrate = control_node.exec!("openstack server migrate --shared-migration #{@new_instance_id}")

  # it may take some time before the instance turns verify_resize
  wait_for "Checking that instance status is verify_resize", max: "300 seconds", sleep: "10 seconds" do
    instance_show = control_node.openstack.server.show(@new_instance_id)
    if instance_show.status == "VERIFY_RESIZE"
      puts "Migration finished, confirming..."
      control_node.exec!("openstack server resize --confirm #{@new_instance_id}")
    break
    end
  end
end

When(/^I migrate KVM instance$/) do
  # get actual host of the instance and migrate it
  @instance_host = @instance_show.send("os-ext-srv-attr:host")
  puts "Instance running on: #{@instance_host}"
  instance_migrate = control_node.exec!("openstack server migrate #{@new_instance_id}")

  # it may take some time before the instance turns verify_resize
  wait_for "Checking that instance status is verify_resize", max: "300 seconds", sleep: "10 seconds" do
    instance_show = control_node.openstack.server.show(@new_instance_id)
    if instance_show.status == "VERIFY_RESIZE"
      puts "Migration finished, confirming..."
      control_node.exec!("openstack server resize --confirm #{@new_instance_id}")
    break
    end
  end
end

Then(/^I expect the instance will run on different host$/) do
  instance_show = control_node.openstack.server.show(@new_instance_id)
  instance_host = instance_show.send("os-ext-srv-attr:host")
  puts "Instance running on: #{instance_host}"
  expect(@instance_host).not_to eq(instance_host)

end

Then(/^will be in state "([^"]*)"$/) do |arg1|
  wait_for "Checking that instance status is ACTIVE", max: "40 seconds", sleep: "10 seconds" do
    instance_show = control_node.openstack.server.show(@new_instance_id)
    break if instance_show.status == "ACTIVE"
  end
end

Then(/^I turn off the instance\(so it will not use resources\)$/) do
  control_node.exec!("openstack server stop #{@new_instance_id}")
  wait_for "Checking that instance status is SHUTOFF", max: "120 seconds", sleep: "10 seconds" do
    instance_show = control_node.openstack.server.show(@new_instance_id)
    break if instance_show.status == "SHUTOFF"
  end
end

