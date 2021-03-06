module SfdcBulk
  class SfdcUpsertApi 
    include SfdcBulkApiBase

    # def sobject
    #   self.class.sobject
    # end

    def self.external_id
      "external_id__c"
    end


    def initialize(payload)
      @payload = payload
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


    def create_job_xml
      return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<jobInfo
    xmlns="http://www.force.com/2009/06/asyncapi/dataload">
  <operation>upsert</operation>
  <object>#{self.class.sobject}</object>
  <externalIdFieldName>#{self.class.external_id}</externalIdFieldName>
  <concurrencyMode>Parallel</concurrencyMode>  
  <contentType>XML</contentType>
</jobInfo>
      XML
    end


    def payload_to_xml(payload_part)
      return <<-XMLDATA
<?xml version="1.0" encoding="UTF-8"?>
<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
#{payload_part.map do |orig|
    "\t<sObject>\n" + map_one(orig).map do |k,v|
        if v.blank?
          "\t\t<#{k.to_s} xsi:nil='true'/>"
        else
          "\t\t<#{k.to_s}>#{v}</#{k.to_s}>"
        end
      end.join("\n") + "\n\t</sObject>"
    end.join("\n") 
    }   
</sObjects>
XMLDATA
    end

  end
end