module Canvas
  module Security
    class ServicesJwt
      attr_reader :token_string, :is_wrapped

      def initialize(raw_token_string, wrapped=true)
        @is_wrapped = wrapped
        if raw_token_string.nil?
          raise ArgumentError, "Cannot decode nil token string"
        end
        @token_string = raw_token_string
      end

      def wrapper_token
        return {} unless is_wrapped
        raw_wrapper_token = Canvas::Security.base64_decode(token_string)
        Canvas::Security.decode_jwt(raw_wrapper_token, [signing_secret])
      end

      def original_token
        original_crypted_token = if is_wrapped
          wrapper_token[:user_token]
        else
          Canvas::Security.base64_decode(token_string)
        end
        Canvas::Security.decrypt_services_jwt(original_crypted_token)
      end

      def id
        original_token[:jti]
      end

      def user_global_id
        original_token[:sub]
      end

      def expires_at
        original_token[:exp]
      end

      def self.generate(payload_data, base64=true)
        payload = create_payload(payload_data)
        crypted_token = Canvas::Security.create_encrypted_jwt(payload, signing_secret, encryption_secret)
        return crypted_token unless base64
        Canvas::Security.base64_encode(crypted_token)
      end

      private

      def self.create_payload(payload_data)
        if payload_data[:sub].nil?
          raise ArgumentError, "Cannot generate a services JWT without a 'sub' entry"
        end
        timestamp = Time.zone.now.to_i
        payload_data.merge({
          iss: "Canvas",
          aud: ["Instructure"],
          exp: timestamp + 3600,  # token is good for 1 hour
          nbf: timestamp - 30,    # don't accept the token in the past
          iat: timestamp,         # tell when the token was issued
          jti: SecureRandom.uuid, # unique identifier
        })
      end

      def encryption_secret
        self.class.encryption_secret
      end

      def signing_secret
        self.class.signing_secret
      end

      def self.encryption_secret
        Canvas::DynamicSettings.from_cache("canvas")["encryption-secret"]
      end

      def self.signing_secret
        Canvas::DynamicSettings.from_cache("canvas")["signing-secret"]
      end
    end
  end
end
