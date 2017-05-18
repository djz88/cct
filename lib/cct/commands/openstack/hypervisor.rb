module Cct
  module Commands
    module Openstack
      class Hypervisor < Command
        self.command = ["hypervisor"]
		def list *options
		  super(*(options << {row: Struct.new(:id, :"Hypervisor Hostname")}))
		end
      end
    end
  end
end
