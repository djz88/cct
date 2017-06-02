module StepHelpers
  def validate_admin!
    step "the admin node responds to a ping"
    step "I can establish SSH connection"
    step "I can reach the crowbar API"
  end
end

  def delete_old_instances!(server_id)
    puts("old instance #{server_id } found - deleting")
    control_node.exec!("openstack server delete #{server_id}")
  end
