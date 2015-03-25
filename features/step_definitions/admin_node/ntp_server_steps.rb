Given(/^the NTP Server is running$/) do
  expect(admin_node.exec!("service ntp status")).to match(/running/)
end

When(/^I request server for estimated correct local date and time$/) do
  expect(`sntp #{admin_node.ip}`).to match(/Started sntp/)
end

Then(/^I receive a response within the "([^"]*)" seconds timeout$/) do |to_seconds|
  timeout(to_seconds.to_f) { `sntp #{admin_node.ip}`}
end

