module SfdcBulk
  class SfdcApi

    attr_accessor :job_id, :batch_id, :result_id

    def session_id
      @connection ||= Connection.new
      @connection.session_id
    end

    def close_job_xml
      return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
  <state>Closed</state>
</jobInfo>
XML
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

    def close_job
      call_api("#{job}/#{@job_id}",close_job_xml,{"Content-Type"=> "application/xml"})
    end

    def start_new_batch
      @batch_id = call_api(batch, sfdc_data , {"Content-Type"=> "text/csv"}) do |result|
        result["batchInfo"]["id"]
      end
    end

    def is_completed_batch
      state = call_api("job/#{@job_id}/batch/#{@batch_id}") {|result| result["batchInfo"]["state"]}
      raise "Failed" if state == "Failed"
      "Completed" == state
    end

    def base_sfdc_url
      instance = $sfdcbulk_configuration.sfdc_instance
      api_version = $sfdcbulk_configuration.sfdc_api_version

      "https://#{instance}.salesforce.com/services/async/#{api_version}"

    end


    def call_api(service,params=nil,options={},&block)
      RestClient.log = 'stdout'

      session_id
      bulk_api_url = "#{base_sfdc_url}/#{service}"

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