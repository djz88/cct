Given(/^At least (\d+) Xen Hypervisors are available$/) do |arg1|
  # get hypervisors and count Xen's ones - for migration at least 2
  hashypervisor_xen = 0
  @hypervisors = control_node.openstack.hypervisor.list 
  expect(@hypervisors).not_to be_empty

  @hypervisors.each do |h| 
    hypervisor = control_node.openstack.hypervisor.show(h.id)
    hashypervisor_xen = (hashypervisor_xen + 1) if hypervisor.hypervisor_type == "Xen"
  end
  expect(hashypervisor_xen).to be > arg1.to_i
end

Given(/^At least (\d+) Compute nodes must be enabled$/) do |arg1|
  # get hypervisors and count Xen's ones - for migration we need 2
    enabled_host_list = control_node.exec!("openstack host list -f value --zone nova").output
  expect(enabled_host_list.each_line(separator=$/).to_a.count).to be >= arg1.to_i


end

Given(/^Image is available$/) do
  # check image
  my_config     = config["features"]["images"]["xen_hvm"]
  @image_name   = "jeos"
  images = control_node.openstack.image.list
  images.each do |i|
    @image_id   = i.id if i.name == @image_name
  end
  expect(@image_id).not_to be_empty
end

When(/^I create an instance$/) do
  def delete_old_instances(server_id) 
    puts("old instance #{server_id } found - deleting")
    control_node.exec!("openstack server delete #{server_id}")
  end
  # TODO add --key-name zkubala
  # clean old instances
  @servers = control_node.openstack.server.list
  @instance_name = "xen_mig_instance"
  @servers.each do |s|
    s.name == @instance_name and delete_old_instances(s.id)
  end
  new_instance = control_node.exec!("openstack server create -f shell --flavor m1.smaller --image jeos --security-group default -c id #{@instance_name}")
  @new_instance_id = new_instance.output[4, 36] 
  puts ("New instance id: #{@new_instance_id}")
end

When(/^Instance is running$/) do
  # it may take some time before the instance turns active
  wait_for "Checking that instance status is active", max: "120 seconds", sleep: "4 seconds" do
    @instance_show = control_node.openstack.server.show(@new_instance_id)
    break if @instance_show.status == "ACTIVE"
  end
end

When(/^I migrate instance$/) do
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

