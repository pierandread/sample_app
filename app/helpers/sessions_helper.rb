module SessionsHelper
  # login given user
  def log_in(user)
    # session is saved in cookie encrypted
    session[:user_id] = user.id
  end

  # returns current loggedin user if any
  def current_user
    return unless session[:user_id]

    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in? 
    !current_user.nil?
  end
end
