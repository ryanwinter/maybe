module Plaidable
  extend ActiveSupport::Concern

  class_methods do
    def plaid_us_provider
      Provider::Plaid.new(Rails.application.config.plaid, :us) if Rails.application.config.plaid
    end

    def plaid_eu_provider
      Provider::Plaid.new(Rails.application.config.plaid_eu, :eu) if Rails.application.config.plaid_eu
    end

    # def simplefin_provider
    #   Provider::Simplefin.new
    # end

    def plaid_provider_for_region(region)
      region.to_sym == :eu ? plaid_eu_provider : plaid_us_provider
    end
  end

  private
    def eu?
      raise "eu? is not implemented for #{self.class.name}"
    end

    def plaid_provider(region)
      case region.to_sym
      when :eu
        Provider::Plaid.new(Rails.application.config.plaid_eu, :eu)
      when :us
        Provider::Plaid.new(Rails.application.config.plaid, :us)
      when :simplefin
        Provider::Simplefin.new(Rails.application.credentials.simplefin_access_url)
      else
        Rails.logger.error "Invalid region: #{region}"
      end
    end
end
