require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "full title helper" do
    assert_equal full_title, "Ruby"
    assert_equal full_title("Contact"), "Contact | Ruby"
  end
end