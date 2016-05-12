module SfdcLoadable
    require "csv"
    extend ActiveSupport::Concern

    def initialize_target_row(target_row,sfdc_row)
      mapping = self.mapping
      ch = target_class.columns_hash
      sfdc_row.each do |k,v|
        cinfo = ch[k]
        next if cinfo.nil?
        target_name = mapping[k]
        v = nil if !v.nil? && v.empty?
        target_row[target_name] = v
      end
      return target_row
    end

    def reload_from_sfdc(method: )
      if method.nil?
        method = self.class.sfdc_refresh_method
      end
      filename = self.run
      self.import(filename,method)
    end

    def import(filename,method)
      if method.nil?
        method = self.class.sfdc_refresh_method
      end
      if method == :truncate
        target_class.connection.execute(truncate_sql_statement(table_name: target_class.table_name))
      end
      
      csv = CSV.open(filename,headers:true,header_converters:lambda { |h| h.downcase})
      csv.each do |row|
        if method == :truncate
          target_row = target_class.new
        else
          target_row = target_class.find_by(self.mapping["id"] => row["id"]) || target_class.new
        end
        initialize_target_row(target_row,row)
        target_row.save
      end
      true
    end

    def truncate_sql_statement(params)
<<-SQL
TRUNCATE TABLE #{params[:table_name]};
SQL
    end



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

      def set_excluded_attributes(attributes)
        @excluded_attributes = [attributes].flatten
      end
      
      def excluded_attributes
        @excluded_attributes || []
      end

      def set_sfdc_limit(limit)
        @slimit = limit
      end

      def set_sfdc_refresh_method(method)
        @srefresh_method = method
      end


      def sobject
        @sobject || self.name.split("::")[1]
      end

      def sfdc_where
        @swhere 
      end

      def sfdc_limit
        @slimit
      end

      def sfdc_refresh_method
        @srefresh_method ||= :upsert
      end

    end

end