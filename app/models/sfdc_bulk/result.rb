module SfdcBulk
	class Result
		attr_accessor :current_job, :current_batch
		
		def initialize(job: , batch: )
			self.current_job = job
			self.current_batch = batch
		end

		def url(result_id)
      "#{current_batch.url}/result/#{result_id}"
		end

	  def result_ids
		  @result_ids ||= [current_job.sfdc_api.call_api([current_batch.url,"result"].join("/")) do |result|
	  	  result["result_list"]["result"]
	    end].flatten
	  end


    def get_as_file
      filename= "tmp/bulk_result_#{current_job.sfdc_api.target_class.name.underscore.gsub("/","_")}_#{Time.now.to_i}.csv"
      File.open(filename,"w") do |f|
        result_ids.each_with_index do |result_id,index|
          result = current_job.sfdc_api.call_api(self.url(result_id))
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