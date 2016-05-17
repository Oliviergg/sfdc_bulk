module SfdcBulk
	class Job

		def sfdc_api
			@sfdc_api
		end

		def url
      "job/#{@job_id}"
    end


		def batches
			@batches ||= []
		end

		def initialize(sfdc_api: sfdc_api)
			@sfdc_api = sfdc_api
		end

    def start &block
      @job_id = sfdc_api.call_api("job", sfdc_api.create_job_xml, {"Content-Type"=> "application/xml"}) do |result|
        result["jobInfo"]["id"]
      end
      block.call(self)
      self
    end


    def start_new_batch(data,type: "text/csv")
    	b = SfdcBulk::Batch.new(data, job: self)
    	b.content_type = type
    	batches << b
    	b.start
    end


    def check_status
    	batches.map(&:check_status)
    end

    def is_completed
			return batches.select{|b| b.status == "Queued" || b.status == "InProgress" || b.status.nil? }.count == 0
    end

    def failed_batches
			return batches.select{|b| b.status == "Failed" || b.status == "Not Processed"} 
    end


    def close
      sfdc_api.call_api(self.url, close_job_xml, {"Content-Type"=> "application/xml"})
    end

    def to_s
  	"Job : #{@job_id}"
    end

    def wait_for_completion
      completed = false
      sleep 10
      check_status
      log_status
      while !is_completed
        sleep 30 
        check_status
        log_status
      end
      return failed_batches.count == 0
    end

    def close_job_xml
      return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
  <state>Closed</state>
</jobInfo>
XML
    end


    def log_status
      Rails.logger.info(self.to_s)
      self.batches.each do |b|
        Rails.logger.info("\t" + b.to_s) 
      end
    end



end

end