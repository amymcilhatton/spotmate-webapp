module ApplicationHelper
  def human_distance(distance_miles)
    return "Same gym as you" if distance_miles.nil? || distance_miles < 0.1
    return "Less than 1 mile from your gym" if distance_miles < 1

    "About #{distance_miles.round(1)} miles from your gym"
  end
end
