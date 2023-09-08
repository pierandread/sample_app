# frozen_string_literal: true

require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  test 'invalid signup information' do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: { user: { name: '',
                                        email: 'not@valid',
                                        password: 'asdasd',
                                        password_confirmation: 'asd123' } }
    end
    assert_response :unprocessable_entity
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.alert-danger'

  end

  test 'valid signup information' do
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name: 'Example',
                                         email: 'user@example.com',
                                         password: 'password',
                                         password_confirmation: 'password' } }
    end
    follow_redirect!
    assert_template 'users/show'
    assert_not flash[:error]
  end
end
