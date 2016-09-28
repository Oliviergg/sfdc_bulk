module SfdcBulkQueryConfig
    require "csv"
    extend ActiveSupport::Concern

    # methods defined here are going to extend the class, not the instance of it
    module ClassMethods
      @sobject = nil
      @swhere = nil
      @slimit = nil


      def base_class
        a = self.name.split("::")
        a.pop
        a.join("::").constantize
      end

      def set_sfdc_object(name)
        @sobject = name
      end

      def set_sfdc_where(where)
        @swhere = where
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

    def querier_class
      self.class
    end
    
    def target_class
      self.class.base_class
    end


    def excluded_attributes=(exc)
      @excluded_attributes = [exc].flatten
    end
    
    def excluded_attributes
      @excluded_attributes || []
    end



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

    def import_fast(filename)
        target_class.querier_instance.truncate
        columns = target_class.columns_hash
        csv = open_csv(filename)
        
        target_columns = nil

        csv.each_slice(1000) do |rows|
          
          target_values = rows.map do |row|
            h = row.to_h
            if target_columns.nil?
              target_columns = h.keys.map do |column|
                self.mapping[column]
              end
            end            
            h.values.map { |v| v.blank? ? nil : v }
          end
          target_class.import target_columns, target_values, validate: false
        end
    end

    def open_csv(filename)
      CSV.open(filename,headers:true,header_converters:lambda { |h| h.downcase})
    end

    def import(filename,method)
      if method.nil?
        method = self.class.sfdc_refresh_method
      end

      if method.to_sym == :truncate
        return import_fast(filename)
      end
      
      open_csv(filename).each do |row|
        target_row = target_class.find_by(self.mapping["id"] => row["id"]) || target_class.new
        initialize_target_row(target_row,row)
        begin
          target_row.save
        rescue => e
          Rails.logger.info("#{e.inspect} Cant import #{row} ")
        end
      end
      true
    end

    def truncate_sql_statement(params)
<<-SQL
TRUNCATE TABLE #{params[:table_name]};
SQL
    end

    def truncate
      target_class.connection.execute(truncate_sql_statement(table_name: target_class.table_name))
    end



end