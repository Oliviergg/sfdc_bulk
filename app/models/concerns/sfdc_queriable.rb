module SfdcQueriable
	extend ActiveSupport::Concern

  module ClassMethods
  	def querier_instance
  		"#{self.name}::Querier".constantize.new
  	end

	  def reload_from_sfdc(method: nil )
	  	querier_instance.reload_from_sfdc(method: method)
	  end

	  def import(filename:  ,method: nil)
	  	querier_instance.import(filename,method)
	  end
	end
end
