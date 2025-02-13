require "date"
require "json"
require "ostruct"

# shortcut to define complex OpenStructs from has
class Hash
  def to_o
    JSON.parse(to_json, object_class: OpenStruct)
  end
end

class Provider::Simplefin
  def initialize(access_url)
    @access_url = access_url
  end

  def get_items()
    get_orgs
  end

  def get_item(item)
    get_items.detect { |org| org.item.institution_id == item.plaid_id }
  end

  def get_item_accounts(item)
    get_item(item)
  end

  def get_item_transactions(item)
    # get the account list for this financial institution for the request
    accounts = Array.new
    item.plaid_accounts.each do |account|
      accounts.push(account.plaid_id)
    end

    transactions = OpenStruct.new(added: [], modified: [], removed: [])

    response = get("accounts", {
      "start-date" => item.last_synced_at.to_i, 
      "accounts" => accounts
    })

    response.each do |account|
      account.transactions.each do |transaction|
        transactions.added.push({
          :account_id => account.id,
          :transaction_id => transaction.id,
          :name => transaction.description,
          :date => Time.at(transaction.posted).iso8601,
          :amount => transaction.amount,
          :merchant_name => transaction.payee,
          :iso_currency_code => account.currency,
          :personal_finance_category => {
            :primary => "Other" # I'm not sure how to categorize the accounts, this might need to be a manual step
          }
        }.to_o)
      end
    end

    transactions
  end

  private
    attr_reader :access_url

    def get_orgs
      orgs = Array.new

      # extract the info into these formats:
      #   https://plaid.com/docs/api/items/
      #   https://plaid.com/docs/api/accounts/
      accounts = get("accounts", { "balances-only" => "1" })
      accounts.each do | account |
        index = orgs.find_index { |org| org.item.institution_id == account.org.id }
        if index == nil
          # create the org if it doesnt exist
          orgs.push({
            :available_products => "",
            :billed_products => "",
            :item => {
              :institution_id => account.org.id,
              :institution_name => account.org.name
            },
            :accounts => []
          }.to_o)
          index = orgs.length - 1
        end
  
        # add the account to the existing org
        orgs[index].accounts.push({
          :account_id => account.id,
          :name => account.name,
          :type => "other", # seems to be no way to detect the account type, just put as Other for now
          :balances => {
            :current => account.balance,
            :available => account["available-balance"],
            :iso_currency_code => account.currency,
          }
        }.to_o)
      end

      return orgs
    end

    def get(endpoint, params = {})
      conn = Faraday::Connection.new(access_url)
      response = conn.get(endpoint, params)
#      Rails.logger.info("simplefin request=#{access_url}/#{endpoint}?#{params}, response=#{response.body}")

      JSON.parse(response.body, object_class: OpenStruct).accounts
    end
end
