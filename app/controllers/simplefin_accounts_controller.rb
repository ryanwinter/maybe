class SimplefinAccountsController < ApplicationController
  layout :with_sidebar

  def index
    create_items()

    redirect_to accounts_path, notice: t(".success")
  end

  private

  def create_items()
    update_access_url()

    provider = Provider::Simplefin.new() 
    accounts = provider.get_accounts()
    # item = Current.family.plaid_items.find_by(plaid_id: "simplefin")
    # if item.blank?
    #   setup_token = ENV["SIMPLEFIN_SETUP_TOKEN"]
    #   claim_url = Base64.decode64(setup_token)
  
    #   response = Faraday.post(claim_url, nil, content_length: 0)
  
    #   unless response.success?
    #     Rails.logger.error "Simplefin invalid/expired setup token, response #{response.body}"
    #   end

    #   # Current.family.update(simplefin_access_token: response.body)
    #   item = Current.family.plaid_items.create!(
    #     name: "Simplefin",
    #     plaid_id: "simplefin",
    #     access_token: response.body,
    #     plaid_region: "simplefin"
    #   )
    # end

    # item.sync_later
  end

  def update_access_url()
    token = Current.family.simplefin_access_url

    if token.blank?
      setup_token = ENV["SIMPLEFIN_SETUP_TOKEN"]
      claim_url = Base64.decode64(setup_token)
  
      response = Faraday.post(claim_url, nil, content_length: 0)
  
      unless response.success?
        Rails.logger.error "Simplefin invalid/expired setup token, response #{response.body}"
        return "Simplefin invalid/expired setup token, response #{response.body}"
      end

      Current.family.update!(simplefin_access_url: response.body)
    end

    Rails.logger.info("simplefin token is #{Current.family.simplefin_access_token}")
  end
end
