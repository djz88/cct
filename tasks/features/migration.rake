namespace :feature do
  feature_name "Instance migration"

  namespace :migration do
    desc "Test Xen migration"
    feature_task :xen, tags: :@xen

    feature_task :all
  end

  desc "Complete verification of 'Instance migration' feature"
  task :migration => "migration:all"
end
