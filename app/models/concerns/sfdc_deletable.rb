module SfdcDeletable
	extend ActiveSupport::Concern

  module ClassMethods
  	def deleter_klass
  		"#{self.name}::Deleter".constantize
  	end

    def delete_sfdc(payload)
      deleter_klass.new(payload).run
    end

	end
end
