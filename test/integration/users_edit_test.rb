require "test_helper"

class UsersEditTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  test 'unsuccessful edit' do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: { user: {name:'',
                                             email: 'foo@invalid',
                                             password: 'foo',
                                             password_confirmation: 'bar'}}
    assert_template 'users/edit'
    assert_select 'div.alert', 'The form contains 4 errors.'
  end

  test 'successful edit' do
    get edit_user_path(@user)
    log_in_as(@user)
    assert_redirected_to edit_user_path(@user)
    assert session[:forwarding_url].nil?
    name = 'Foo'
    email = 'foo@bar.com'
    patch user_path(@user), params: {user: {name:, email:, password: '',
                                            password_confirmation: 'bar'}}
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
  end
end
