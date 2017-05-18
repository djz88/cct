namespace :feature do
  feature_name "Instance migration"

  namespace :migration do
    desc "Test KVM migration"
    feature_task :kvm, tags: :@kvm

    desc "Test Xen migration"
    feature_task :xen, tags: :@xen
  end

  desc "Complete verification of 'Instance migration' feature"
  task :migration => "migration:kvm"
end
