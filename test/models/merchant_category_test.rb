require "test_helper"

class MerchantCategoryTest < Minitest::Test
  def test_matches_a_merchant_that_starts_with_a_listed_name
    assert_equal "Food & beverage", MerchantCategory.for("SYSCO PHILA 8827")
  end

  def test_ignores_case_when_matching
    assert_equal "Food & beverage", MerchantCategory.for("Sysco Phila 8827")
  end
end
