require "test_helper"

class MerchantCategoryTest < Minitest::Test
  def test_matches_a_merchant_that_starts_with_a_listed_name
    assert_equal "Food & beverage", MerchantCategory.for("SYSCO PHILA 8827")
  end

  def test_ignores_case_when_matching
    assert_equal "Food & beverage", MerchantCategory.for("Sysco Phila 8827")
  end

  def test_returns_nil_for_a_merchant_not_on_the_list
    assert_nil MerchantCategory.for("AMZN MKTP US*2K4X9")
  end

  def test_returns_nil_for_a_missing_merchant
    assert_nil MerchantCategory.for(nil)
  end

  def test_ignores_surrounding_whitespace
    assert_equal "Rent", MerchantCategory.for("  MAINLINE PROPERTIES LLC")
  end
end
