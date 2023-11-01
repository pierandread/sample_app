class ApplicationController < ActionController::Base
  include SessionsHelper

  private

  #  Confirm a logged-in user
  def logged_in_user
    return if logged_in?

    store_location
    flash[:danger] = 'Please log in.'
    redirect_to login_url, status: :see_other
  end
end
