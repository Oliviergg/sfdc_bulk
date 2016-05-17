module SfdcBulkQueryApi
    extend ActiveSupport::Concern


    def create_job_xml
      return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<jobInfo
    xmlns="http://www.force.com/2009/06/asyncapi/dataload">
  <operation>query</operation>
  <object>#{self.class.sobject}</object>
  <concurrencyMode>Parallel</concurrencyMode>
  <contentType>CSV</contentType>
</jobInfo>
      XML
    end


    def run
      self.current_job = SfdcBulk::Job.new(sfdc_api: self)

      self.current_job.start do |job|
        job.start_new_batch(query)
      end

      success = current_job.wait_for_completion
      if !success
        self.current_job.log_status
        raise "A Batch Failed. more info : see job #{@current_job.joid}"
      end

      filenames = self.current_job.batches.map do |batch|
        result = SfdcBulk::Result.new(job:current_job, batch:batch)
        result.get_as_file
      end

      current_job.close
      filenames.first
    end

end