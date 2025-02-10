# require "base64"

# Token = Struct.new(:item_id, :access_token)

class Provider::Simplefin
  attr_reader :access_url

  def initialize()
    @access_url = Current.family.simplefin_access_url
    Rails.logger.info("##simplefin_init #{access_url}")
  end

  # def exchange_public_token(token)
  #   Token.new("simplefin", access_token)
  # end

  def get_accounts()
    get("accounts?balances-only=1")
  end

  private
    def get(endpoint)
      conn = Faraday::Connection.new(access_url)
      Rails.logger.info(conn)

      response = conn.get(endpoint)
      Rails.logger.info("simplefin request=#{access_url}/#{endpoint}, response=#{response.body}")
    end

end
