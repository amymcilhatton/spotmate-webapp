class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def require_admin!
    return if current_user&.role_admin?

    redirect_to root_path, alert: "Admin access required."
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name pilot_updates])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name pilot_updates])
  end
end
