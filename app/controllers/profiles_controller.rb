class ProfilesController < ApplicationController
  def show
    @profile = profile
  end

  def edit
    @profile = profile
  end

  def update
    @profile = profile
    if @profile.update(profile_params)
      remove_avatar if params.dig(:profile, :remove_avatar) == "1"
      attach_avatar_from_params
      update_user_name
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile
    current_user.profile || current_user.build_profile
  end

  def profile_params
    permitted = params.require(:profile).permit(
      :age,
      :age_range,
      :gender,
      :home_gym_name,
      :home_city,
      :gym,
      :experience_band,
      :women_only,
      :travel_preference,
      :preferred_partner_age_min,
      :preferred_partner_age_max,
      goals: [],
      preferred_buddy_days: [],
      preferred_buddy_times: [],
      privacy_matrix: {}
    )
    normalize_array_fields(permitted, :goals, :preferred_buddy_days, :preferred_buddy_times)
    enforce_women_only_guard(permitted)
    permitted
  end

  def normalize_array_fields(permitted, *keys)
    keys.each do |key|
      permitted[key] = Array(permitted[key]).reject(&:blank?)
    end
  end

  def enforce_women_only_guard(permitted)
    return unless permitted[:gender] == "male"

    permitted[:women_only] = false
  end

  def attach_avatar_from_params
    avatar = params.dig(:profile, :avatar)
    return unless avatar.is_a?(ActionDispatch::Http::UploadedFile)

    current_user.avatar.attach(avatar)
  end

  def remove_avatar
    current_user.avatar.purge if current_user.avatar.attached?
  end

  def update_user_name
    return unless params.dig(:profile, :name)

    current_user.update(name: params.dig(:profile, :name).presence)
  end
end
