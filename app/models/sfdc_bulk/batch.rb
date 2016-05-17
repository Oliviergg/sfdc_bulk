class SfdcBulk::Batch
	attr_accessor :status, :current_job, :content_type

  def url
    "#{current_job.url}/batch/#{@batch_id}"    	
  end

	def initialize(payload, job:)
		@payload = payload
		self.current_job = job
	end

  def start
    @batch_id = current_job.sfdc_api.call_api([current_job.url,"batch"].join("/"), @payload , {"Content-Type"=> content_type}) do |result|
      result["batchInfo"]["id"]
    end
  end

  def check_status
    self.status = current_job.sfdc_api.call_api(self.url) {|result| result["batchInfo"]["state"]}
  end

  def to_s
  	"Batch : #{@batch_id} #{status}"
  end


end