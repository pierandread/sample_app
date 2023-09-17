class SessionController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      # login
    else
      flash[:danger] = 'Invalid email/password combination' # no bueno
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy; end
end
