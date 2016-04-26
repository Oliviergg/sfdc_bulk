module SfdcQuerySoql
    extend ActiveSupport::Concern


      def mapping
        excluded_attributes_default = [:id, :created_at, :updated_at]

        attrs = target_class.attribute_names.dup
        
        excluded_attributes_default.each do |attr| attrs.delete(attr.to_s) end
        target_class.excluded_attributes.each do |attr| attrs.delete(attr.to_s) end
        

        sfdc_default_attrs = {
          "id" => "sfdc_id"
        }
        attrs.delete("sfdc_id")

        sfdc_attrs = attrs.map do |attr|
          [attr,attr]
        end.to_h

        sfdc_default_attrs.merge(sfdc_attrs)
      end

      def field_list
         self.mapping.keys.join(",") 
      end

      def where
        nil
      end
      
      def limit
        nil
      end

      def query
        soql = "SELECT #{field_list} FROM #{self.sobject}"
        soql = "#{soql} WHERE #{target_class.sfdc_where}" if target_class.sfdc_where
        soql = "#{soql} LIMIT #{target_class.sfdc_limit}" if target_class.sfdc_limit
        soql
      end

      def sfdc_data
        query
      end


    # methods defined here are going to extend the class, not the instance of it
    module ClassMethods

    end

  end
