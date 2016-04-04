module SfdcSoql
    extend ActiveSupport::Concern


      def target_class
        self.class.name.split("::").last.constantize
      end

      def mapping

        attrs = target_class.attribute_names.dup
        attrs.delete("id")
        attrs.delete("sfdc_id")
        attrs.delete("created_at")
        attrs.delete("updated_at")
        sfdc_default_attrs = {
          "Id" => "sfdc_id"
        }

        sfdc_attrs = attrs.map do |attr|
          attr_info = target_class.columns_hash[attr]

          to_attr = if attr_info.type == :boolean
            {
              attr: attr,
              transf: "SELECT IF(STRCMP(@#{attr},'true'),1,0)"
            }
          else
            attr
          end

          [attr,to_attr]
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


    # methods defined here are going to extend the class, not the instance of it
    module ClassMethods

    end

  end
