require "date"
require "json"

class Provider::Simplefin
  # Organisational structures
  Organisation = Struct.new(
    :institution_id,
    :institution_name,
    :available_products,
    :billed_products,
     keyword_init: true
  )
  
  OrganisationItem = Struct.new(
    :item,
    :accounts,
    keyword_init: true
  )

  # Account structures
  Account = Struct.new(
    :account_id,
    :name,
    :type,
    :subtype,
    :balances,
    keyword_init: true
  )
  
  Balance = Struct.new(
    :current,
    :available,
    :iso_currency_code,
    keyword_init: true
  )
  
  # Transactional structures
  FinanceCategory = Struct.new(
    :primary,
    keyword_init: true
  )
  
  Transaction = Struct.new(
    :account_id,
    :transaction_id,
    :name,
    :date,
    :amount,
    :merchant_name,
    :iso_currency_code,
    :personal_finance_category,
    keyword_init: true
  )
  
  Transactions = Struct.new(
    :added,
    :modified,
    :removed,
    :cursor,
    keyword_init: true
  )

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
    transactions = Transactions.new(
      added: [], 
      modified: [], 
      removed: [],
      cursor: "" # unused, but the plaid_item needs it to be there. Used by Plaid
    )

    # get the account list for this financial institution for the request
    accounts = Array.new
    item.plaid_accounts.each do |account|
      accounts.push(account.plaid_id)
    end

    response = get("accounts", {
      "start-date" => item.last_synced_at.to_i, 
      "accounts" => accounts
    })

    response.each do |account|
      account["transactions"].each do |transaction|
        transactions.added.push(Transaction.new(
          :account_id => account["id"],
          :transaction_id => transaction["id"],
          :name => transaction["description"],
          :date => Time.at(transaction["posted"]).iso8601,
          :amount => transaction["amount"],
          :merchant_name => transaction["payee"],
          :iso_currency_code => account["currency"],
          :personal_finance_category => FinanceCategory.new(
            :primary => "Other" # I'm not sure how to categorize the accounts, this might need to be a manual step
          )
        ))
      end
    end

    return transactions
  end

  def get_item_investments(item)
    return OpenStruct.new(holdings: [], transactions: [], securities: [])
  end

  def get_item_liabilities(item)
    return OpenStruct.new(credit: [], mortgage: [], student: [])
  end

  private
    attr_reader :access_url

    def get_orgs
      orgs = Array.new

      # extract the info into these formats:
      #   https://plaid.com/docs/api/items/
      #   https://plaid.com/docs/api/accounts/
      response = get("accounts", {
        "balances-only" => "1" 
      })
      response.each do | account |
        index = orgs.find_index { |org| org.item.institution_id == account["org"]["id"] }
        if index == nil
          orgs.push(OrganisationItem.new(
            :item => Organisation.new(
              :institution_id => account["org"]["id"],
              :institution_name => account["org"]["name"],
              :available_products => "",
              :billed_products => ""
            ),
            :accounts => []
          ))

          index = orgs.length - 1
        end
  
        # add the account to the existing org
        orgs[index].accounts.push(Account.new(
          :account_id => account["id"],
          :name => account["name"],
          :type => "other", # seems to be no way to detect the account type, just put as other for now
          :subtype => "",
          :balances => Balance.new(
            :current => account["balance"],
            :available => account["available-balance"],
            :iso_currency_code => account["currency"]
          )
        ))
      end

      return orgs
    end

    def get(endpoint, params = {})
      conn = Faraday::Connection.new(access_url)
      response = conn.get(endpoint, params)
#      Rails.logger.info("simplefin request=#{access_url}/#{endpoint}?#{params}, response=#{response.body}")

      return JSON.parse(response.body)["accounts"]
    end
end
