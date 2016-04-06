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
        @sobject || self.name.split("::").last
      end

      def sfdc_where
        @swhere 
      end
      def sfdc_limit
        @slimit
      end

      def sfdc_api_instance(target_class:)
        return @instance unless @instance.nil?
        klass = Class.new(SfdcBulk::SfdcQueryApi)
        @instance ||= klass.new(target_class: target_class)
      end


      def load_data_sql(filename)
        build_sql(filename, sfdc_api_instance(target_class: self).mapping )
      end

      def reload_from_sfdc
        load_in_db(sfdc_api_instance(target_class: self).run)
      end

      def load_in_db(filename)
        statements = [load_data_sql(filename)].flatten
        statements.each do |statement|
          self.connection.execute(statement)
        end
        true
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
                          .join(",\n")

        unless set_list.empty?
          "SET \n#{set_list}\n;"
        end
      end

      def truncate_sql_statement(params)
<<-SQL
TRUNCATE TABLE #{params[:table_name]};
SQL
      end
      def load_data_sql_statement(params)
<<-SQL
LOAD DATA LOCAL INFILE '#{params[:filename]}' 
INTO TABLE #{params[:table_name]}
 FIELDS TERMINATED BY ',' 
 ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
  (#{prepare_field_list(params[:mapping])})
  #{prepare_set_list(params[:mapping])}
SQL
      end

      def build_sql(filename, mapping)
        statements = []
        statements << truncate_sql_statement(table_name: self.table_name)
        statements << load_data_sql_statement(table_name: self.table_name,filename: filename, mapping: transform_mapping(mapping))

        statements
      end


    end

end