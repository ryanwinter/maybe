class SimplefinAccountsController < ApplicationController
  @items

  def index
    # if create_items()
    #   redirect_to accounts_path, notice: t(".success")
    # else
    #   redirect_to accounts_path, alert: t(".error")
    # end
    # SimplefinJob.perform_later(self)
  end

  def index_lazy
    get_items
  end

  private
    def get_items()
      access_url = get_access_url()

      if access_url.nil?
        return false
      end

      provider = Provider::Simplefin.new(access_url) 
      @items = provider.get_items()

      @items.each do | item |
        # Create the item if it doesn't exist
        if !Current.family.plaid_items.find_by(plaid_id: item.item.institution_id).present?
          item = Current.family.plaid_items.create!(
              plaid_id: item.item.institution_id,
              name: item.item.institution_name,
              access_token: "simplefin",
              plaid_region: "simplefin"
          )
          item.sync_later
        end
      end

      return true
    end

    def get_access_url()
      access_url = Rails.application.credentials.simplefin_access_url
      setup_token = Rails.application.credentials.simplefin_setup_token
      new_setup_token = ENV["SIMPLEFIN_SETUP_TOKEN"]

      # if we havent generated an access_url yet, or if the setup token has changed, refresh credentials
      if access_url.blank? || setup_token != new_setup_token
        Rails.logger.info "Fetching new Simplefin access URL"
        setup_token = new_setup_token
        claim_url = Base64.decode64(setup_token)
    
        response = Faraday.post(claim_url, nil, content_length: 0)
        unless response.success?
          Rails.logger.error "Simplefin invalid/expired setup token, response #{response.body}"
          return nil
        end

        Rails.application.credentials.simplefin_access_url = response.body
        Rails.application.credentials.simplefin_setup_token = setup_token
      end

      Rails.application.credentials.simplefin_access_url
    end
end
