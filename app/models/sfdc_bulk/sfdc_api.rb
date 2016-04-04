module SfdcBulk
  class SfdcApi
    include SfdcBulk::SfdcSoql
    attr_accessor :job_id, :batch_id, :result_id

    def api_version
      "35.0"
    end

    def instance
      "cs87"
    end

    def session_id
      @connection ||= Connection.new
      @connection.session_id
    end

    def sobject
      self.class.name.split("::").last.constantize.sobject
    end

    def create_job_xml
      return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<jobInfo
    xmlns="http://www.force.com/2009/06/asyncapi/dataload">
  <operation>query</operation>
  <object>#{target_class.sobject}</object>
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
      result_to_file
    end

    def job
      "job"
    end
    def batch
      "job/#{@job_id}/batch"
    end
    def result_ids
      "job/#{@job_id}/batch/#{@batch_id}/result"
    end

    def start_new_job
      @job_id = call_api(job,create_job_xml,{"Content-Type"=> "application/xml"}) do |result|
        result["jobInfo"]["id"]
      end
    end

    def start_new_batch
      @batch_id = call_api(batch,query, {"Content-Type"=> "text/csv"}) do |result|
        result["batchInfo"]["id"]
      end
    end

    def get_result_ids
      @result_ids = call_api(result_ids) do |result|
        result["result_list"]["result"]
      end
    end

    def result_to_file
      @result_ids = [@result_ids].flatten
      filename= "tmp/bulk_result_#{sobject.underscore}_#{@job_id}_#{@batch_id}.csv"

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

    def is_completed_batch
      state = call_api("job/#{@job_id}/batch/#{@batch_id}") {|result| result["batchInfo"]["state"]}
      raise "Failed" if state == "Failed"
      "Completed" == state
    end


    def call_api(service,params=nil,options={},&block)
      RestClient.log = 'stdout'
      bulk_api_url = "https://#{instance}.salesforce.com/services/async/#{api_version}/#{service}"
      Rails.logger.info("call api #{sobject}: #{bulk_api_url}")
      headers = { 
        "X-SFDC-Session" => session_id , 
        "charset" => "UTF-8", 
        "Content-Type"=> "application/xml"
      }.merge(options)
      
      result = if params.nil?
        RestClient.get bulk_api_url,headers
      else
        RestClient.post bulk_api_url,params,headers
      end

      if block
        result = HashWithIndifferentAccess.from_xml(result)
        yield result
      else
        result
      end
    end

  end
end