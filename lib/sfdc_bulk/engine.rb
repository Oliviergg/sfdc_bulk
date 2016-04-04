module SfdcBulk
  class Engine < ::Rails::Engine
  	# require "sfdc_bulk/concerns/sfdc_loadable"
		# require_dependency 'toto'
    isolate_namespace SfdcBulk
		# require_dependency 'lib/concerns/models/sfdc_loadable.rb'
  end
end
