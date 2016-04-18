module SfdcLoadable
    require "csv"
    extend ActiveSupport::Concern

    def initialize_with_sfdc_row(sfdc_row)
      mapping = self.class.sfdc_api_instance.mapping
      ch = self.class.columns_hash
      sfdc_row.each do |k,v|
        cinfo = ch[k]
        next if cinfo.nil?
        target_name = mapping[k]
        self[target_name] = v
      end
      return self
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

      def sfdc_api_instance(target_class: self)
        return @instance unless @instance.nil?
        klass = Class.new(SfdcBulk::SfdcQueryApi)
        @instance ||= klass.new(target_class: target_class)
      end

      def reload_from_sfdc
        filename = sfdc_api_instance.run
        import(filename)
      end

      def refresh_from_sfdc
        filename = sfdc_api_instance.run
        import(filename,update_existing:true)
      end


      def import(filename, update_existing: false)
        unless update_existing
          self.connection.execute(truncate_sql_statement(table_name: self.table_name))
        end
        
        csv = CSV.open(filename,headers:true,header_converters:lambda { |h| h.downcase})
        csv.each do |row|
          if update_existing
            target_row = self.find_by(self.sfdc_api_instance.mapping["id"] => row["id"]) || self.new
          else
            target_row = self.new
          end
          target_row.initialize_with_sfdc_row(row)
          target_row.save
        end
        true
      end

      private


      def truncate_sql_statement(params)
<<-SQL
TRUNCATE TABLE #{params[:table_name]};
SQL
      end


    end

end