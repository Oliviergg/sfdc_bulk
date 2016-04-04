module SfdcBulk
	class Configuration
		attr_accessor :sfdc_user_name, :sfdc_password, :sfdc_security_token, :sfdc_login_endpoint
		def initialize(sfdc_user_name:, sfdc_password:, sfdc_security_token:, sfdc_login_endpoint:)
			self.sfdc_user_name = sfdc_user_name
			self.sfdc_password = sfdc_password
			self.sfdc_security_token = sfdc_security_token
			self.sfdc_login_endpoint = sfdc_login_endpoint
			$sfdcbulk_configuration = self
		end

	end
end