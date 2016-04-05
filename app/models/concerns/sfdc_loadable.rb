module SfdcLoadable

    extend ActiveSupport::Concern

    # methods defined here are going to extend the class, not the instance of it
    module ClassMethods
      @sobject = nil
      @swhere = nil
      @slimit = nil

      def set_sfdc_object(name)
        @sobject = name
      end

      def set_sfdc_where(where)
        @swhere = where
      end


      def set_sfdc_limit(limit)
        @slimit = limit
      end

      def sobject
        @sobject || self.name
      end

      def sfdc_where
        @swhere 
      end
      def sfdc_limit
        @slimit
      end


      def load_data_sql(filename)
        unless const_defined?("SfdcBulk::#{self.name}")
          SfdcBulk.const_set(self.name, Class.new(SfdcBulk::SfdcApi))
        end
        build_sql(filename,self.table_name, "SfdcBulk::#{self.new.class.name}".constantize.new.mapping)
      end

      def reload_from_sfdc
        unless const_defined?("SfdcBulk::#{self.name}")
          SfdcBulk.const_set(self.name, Class.new(SfdcBulk::SfdcApi))
        end
        load_in_db "SfdcBulk::#{self.new.class.name}".constantize.new.run
      end

      def load_in_db(filename)
        self.connection.execute("truncate table #{self.table_name}")
        self.connection.execute(load_data_sql(filename))
      end

      private

      def transform_mapping(mapping)
        mapping.map do |attr,to_attr|
          to_attr_info = columns_hash[to_attr]
          case to_attr_info.type
          when :boolean
            {
              attr: to_attr,
              transf: "SELECT IF(STRCMP(@#{to_attr},'true'),1,0)"
            }
          when :datetime
            {
              attr: to_attr,
              transf: "STR_TO_DATE(@#{to_attr},'%Y-%m-%dT%H:%i:%s')"
            }
          else
            to_attr
          end
        end
      end

      def prepare_field_list(mapping)
        mapping.map do |v| 
          if v.is_a?(String) 
            v 
          elsif v.nil?
            nil
          elsif v.is_a?(Hash)
            "@#{v[:attr]}"
          end 
        end.compact.join(", ")
      end


      def prepare_set_list(mapping)

        set_list = mapping.select{ |v| v.is_a?(Hash) }
                          .map{ |v| "#{v[:attr]} = (#{v[:transf]})" }
        if set_list.empty?
          ""
        else
          "SET \n#{set_list.join("\n")}\n;"
        end
      end


      def build_sql(filename, table_name, mapping)
        transformed_mapping =  transform_mapping(mapping)

<<-SQL
LOAD DATA LOCAL INFILE '#{filename}' 
INTO TABLE #{table_name}
 FIELDS TERMINATED BY ',' 
 ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
  (#{prepare_field_list(transformed_mapping)})
  #{prepare_set_list(transformed_mapping)}
SQL

      end


    end

end