namespace :feature do
  feature_name "Controller node"

  namespace :controller do
    desc "Essential system requirements"
    feature_task :system, tags: :@system
	
    desc "Test Xen migration"
    feature_task :xen, tags: :@xen 

    feature_task :all
  end

  desc "Complete verification of 'Controller node' feature"
  task :controller => "controller:all"
end
