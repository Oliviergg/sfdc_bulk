module SfdcUpdatable
	extend ActiveSupport::Concern

  module ClassMethods
  	def updater_klass
  		"#{self.name}::Updater".constantize
  	end

  	def set_sfdc_updatable_attributes(exc)
  		@none_queriable_attributes = exc
  	end

  	def set_sfdc_updatable_attributes
  		@none_queriable_attributes || []
  	end

    def update_sfdc(payload)
      updater_klass.new(payload).run
    end

	end
end
