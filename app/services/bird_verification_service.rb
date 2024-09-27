# app/services/bird_verification_service.rb
class BirdVerificationService
    include HTTParty
    base_uri 'https://api.bird.com/workspaces'  # Replace with actual base URI
  
    def initialize(workspace_id, jwt_token)
      @workspace_id = workspace_id
      @headers = {
        "Authorization" => "Bearer #{jwt_token}",
        "Content-Type" => "application/json"
      }
    end
  
    def send_verification(identifier, steps, locale = "en-US", max_attempts = 3, timeout = 600, code_length = 6)
      body = {
        identifier: identifier,
        steps: steps,
        locale: locale,
        maxAttempts: max_attempts,
        timeout: timeout,
        codeLength: code_length
      }
  
      self.class.post("/#{@workspace_id}/verify", headers: @headers, body: body.to_json)
    end
  
    def verify_code(verification_id, code)
      body = { code: code }
      self.class.post("/#{@workspace_id}/verify/#{verification_id}", headers: @headers, body: body.to_json)
    end
  
    def resend_verification(verification_id)
      self.class.post("/#{@workspace_id}/verify/#{verification_id}/resend", headers: @headers)
    end
  
    def failover(verification_id)
      self.class.post("/#{@workspace_id}/verify/#{verification_id}/failover", headers: @headers)
    end
  end