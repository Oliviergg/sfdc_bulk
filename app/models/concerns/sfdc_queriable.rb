module SfdcQueriable
	extend ActiveSupport::Concern

  module ClassMethods
  	def querier_instance
  		inst = "#{self.name}::Querier".constantize.new
  		inst.excluded_attributes=sfdc_none_queriable_attributes
  		inst
  	end

  	def set_sfdc_none_queriable_attributes(exc)
  		@none_queriable_attributes = exc
  	end

  	def sfdc_none_queriable_attributes
  		@none_queriable_attributes || []
  	end

	  def reload_from_sfdc(method: nil )
	  	querier_instance.reload_from_sfdc(method: method)
	  end

	  # def import(filename:  ,method: nil)
	  # 	querier_instance.import(filename,method)
	  # end
	end
end
