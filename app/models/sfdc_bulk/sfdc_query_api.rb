module SfdcBulk
  class SfdcQueryApi < SfdcApi
    include SfdcLoadable
    include SfdcQuerySoql

    def self.base_class
      self.name.split("::")[0..1].join("::").constantize
    end

    def querier_class
      self.class
    end
    
    def target_class
      self.class.base_class
    end

    def sobject
      self.class.sobject
    end

    def create_job_xml
      return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<jobInfo
    xmlns="http://www.force.com/2009/06/asyncapi/dataload">
  <operation>query</operation>
  <object>#{self.sobject}</object>
  <concurrencyMode>Parallel</concurrencyMode>
  <contentType>CSV</contentType>
</jobInfo>
      XML
    end

    def run
      start_new_job
      start_new_batch

      completed = false
      sleep 10
      while !is_completed_batch
        sleep 30 
      end

      get_result_ids
      filename = result_to_file

      close_job
      filename
    end

    def get_result_ids
      @result_ids = call_api(result_ids) do |result|
        result["result_list"]["result"]
      end
    end

    def result_to_file
      @result_ids = [@result_ids].flatten
      filename= "tmp/bulk_result_#{target_class.name.underscore.gsub("/","_")}_#{@job_id}_#{@batch_id}.csv"

      File.open(filename,"w") do |f|
        @result_ids.each_with_index do |result_id,index|
          result = call_api("job/#{@job_id}/batch/#{@batch_id}/result/#{result_id}")
          if index > 0 
            splitted = result.split("\n")
            splitted.shift
            result = splitted.join("\n")
          end
          f.write result
        end
      end
      filename
    end

  end
end