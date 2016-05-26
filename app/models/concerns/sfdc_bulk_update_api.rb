module SfdcBulkUpdateApi
    extend ActiveSupport::Concern

    module ClassMethods
      def sobject
        @sobject || self.name.split("::")[1]
      end
    end


    def create_job_xml
      return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<jobInfo
    xmlns="http://www.force.com/2009/06/asyncapi/dataload">
  <operation>update</operation>
  <object>#{self.class.sobject}</object>
  <concurrencyMode>Parallel</concurrencyMode>
  <contentType>XML</contentType>
</jobInfo>
      XML
    end


    def run
      self.current_job = SfdcBulk::Job.new(sfdc_api: self)

      self.current_job.start do |job|
        @payload.find_in_batches(batch_size: 5000) do |group|
          job.start_new_batch(payload_to_xml(group), type: "application/xml")
        end
      end

      success = current_job.wait_for_completion
      if !success
        self.current_job.log_status
        raise "A Batch Failed. more info : see job #{@current_job.joid}"
      end

      current_job.close

    end

end