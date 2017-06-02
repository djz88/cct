Given(/^At least (\d+) Compute nodes must be enabled$/) do |arg1|
  # get hypervisors and count Xen's ones - for migration we need 2
    enabled_host_list = control_node.exec!("openstack host list -f value --zone nova").output
  expect(enabled_host_list.each_line(separator=$/).to_a.count).to be >= arg1.to_i
end

Given(/^Image is available$/) do
  # check image
  image_name   = "jeos"
  images = images.find {|img| img.name == image_name}
  expect(images).not_to be_empty
end
