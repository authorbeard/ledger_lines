class MerchantCategory
  CATEGORIES_BY_MERCHANT_PREFIX = {
    "SYSCO" => "Food & beverage",
    "US FOODS" => "Food & beverage",
    "RESTAURANT DEPOT" => "Food & beverage",
    "METRO GAS & ELECTRIC" => "Utilities",
    "CITY WATER DEPT" => "Utilities",
    "COMCAST BUSINESS" => "Utilities",
    "HOME DEPOT" => "Repairs & maintenance",
    "ECOLAB" => "Cleaning & supplies",
    "WEBSTAURANT STORE" => "Smallwares & supplies",
    "GUSTO" => "Payroll",
    "INDEED" => "Hiring",
    "7SHIFTS" => "Software",
    "MAINLINE PROPERTIES" => "Rent",
    "TOAST PAYOUT" => "Card sales",
    "DOORDASH PAYOUT" => "Delivery sales",
    "UBER EATS PAYOUT" => "Delivery sales"
  }.freeze

  def self.for(merchant)
    normalized_merchant = merchant.to_s.upcase
    categories_by_merchant.fetch(normalized_merchant) do
      categories_by_merchant[normalized_merchant] =
        CATEGORIES_BY_MERCHANT_PREFIX.find { |prefix, _category| normalized_merchant.start_with?(prefix) }&.last
    end
  end

  def self.categories_by_merchant
    @categories_by_merchant ||= {}
  end
end
