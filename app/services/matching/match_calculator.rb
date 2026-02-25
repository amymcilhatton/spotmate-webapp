require "set"

module Matching
  class MatchCalculator
    OVERLAP_WEIGHT = 0.60
    GOAL_WEIGHT = 0.25
    EXPERIENCE_WEIGHT = 0.15
    WINDOW_LOOKAHEAD_DAYS = 14
    MAX_WINDOWS = 3

    MatchSuggestion = Struct.new(
      :user,
      :score,
      :overlap_windows,
      :reason_tags,
      :shared_goals,
      :overlap_days,
      :overlap_times,
      keyword_init: true
    )

    def initialize(user)
      @user = user
      @profile = user.profile
      @availability = user.availability_slots
    end

    def suggestions(candidates)
      return [] if @profile.nil?

      candidates.filter_map do |candidate|
        suggestion_for(candidate)
      end.sort_by { |suggestion| -suggestion.score }
    end

    def overlap_windows_for(candidate)
      next_overlap_windows(candidate.availability_slots)
    end

    private

    def suggestion_for(candidate)
      candidate_profile = candidate.profile
      return nil if candidate_profile.nil?
      return nil unless compatible?(candidate_profile)
      return nil unless age_range_compatible?(candidate_profile)

      overlap_score = schedule_score(@availability, candidate.availability_slots)
      goal_score = jaccard_similarity(@profile.goals, candidate_profile.goals)
      experience_score = @profile.experience_band == candidate_profile.experience_band ? 1.0 : 0.0

      score = (overlap_score * OVERLAP_WEIGHT) +
              (goal_score * GOAL_WEIGHT) +
              (experience_score * EXPERIENCE_WEIGHT)
      score += preference_bonus(candidate_profile)

      MatchSuggestion.new(
        user: candidate,
        score: score.clamp(0.0, 1.0).round(3),
        overlap_windows: next_overlap_windows(candidate.availability_slots),
        reason_tags: reason_tags_for(candidate_profile),
        shared_goals: shared_goals_for(candidate_profile),
        overlap_days: overlap_days_for(candidate_profile),
        overlap_times: overlap_times_for(candidate_profile)
      )
    end

    def compatible?(candidate_profile)
      return false if @profile.women_only && candidate_profile.gender != "female"
      return false if @profile.travel_preference_same_gym_only? &&
                      same_gym_mismatch?(candidate_profile)
      return false if @profile.travel_preference_same_city? &&
                      @profile.home_city.present? &&
                      @profile.home_city != candidate_profile.home_city

      true
    end

    def same_gym_mismatch?(candidate_profile)
      return true if @profile.home_gym_name.blank? || candidate_profile.home_gym_name.blank?

      @profile.home_gym_name != candidate_profile.home_gym_name
    end

    def age_range_compatible?(candidate_profile)
      return true if @profile.preferred_partner_age_min.blank? || @profile.preferred_partner_age_max.blank?
      return true if candidate_profile.age.blank?
      return false unless candidate_profile.age.between?(@profile.preferred_partner_age_min,
                                                         @profile.preferred_partner_age_max)

      return true if candidate_profile.preferred_partner_age_min.blank? ||
                     candidate_profile.preferred_partner_age_max.blank?
      return true if @profile.age.blank?

      @profile.age.between?(candidate_profile.preferred_partner_age_min,
                            candidate_profile.preferred_partner_age_max)
    end

    def preference_bonus(candidate_profile)
      day_overlap = overlap_count(@profile.preferred_buddy_days, candidate_profile.preferred_buddy_days)
      time_overlap = overlap_count(@profile.preferred_buddy_times, candidate_profile.preferred_buddy_times)

      day_bonus = (day_overlap / 7.0) * 0.05
      time_bonus = (time_overlap / 5.0) * 0.05
      day_bonus + time_bonus
    end

    def overlap_count(list_a, list_b)
      (Array(list_a) & Array(list_b)).size
    end

    def reason_tags_for(candidate_profile)
      tags = []
      overlap_days = overlap_days_for(candidate_profile)
      overlap_times = overlap_times_for(candidate_profile)
      if overlap_days.any?
        tags << "Overlap: #{overlap_days.join('/')}"
      end
      if overlap_times.any?
        tags << "Time: #{overlap_times.join(', ')}"
      end
      shared = shared_goals_for(candidate_profile)
      tags << "Shared goals: #{shared.take(2).map(&:humanize).join(', ')}" if shared.any?
      tags << "Same gym" if same_gym_match?(candidate_profile)
      tags << "Same city" if same_city_match?(candidate_profile)
      tags << "Within preferred age range" if age_range_compatible?(candidate_profile)
      tags << "Experience aligned" if @profile.experience_band == candidate_profile.experience_band
      tags
    end

    def shared_goals_for(candidate_profile)
      Array(@profile.goals) & Array(candidate_profile.goals)
    end

    def overlap_days_for(candidate_profile)
      (Array(@profile.preferred_buddy_days) & Array(candidate_profile.preferred_buddy_days))
        .map(&:capitalize)
    end

    def overlap_times_for(candidate_profile)
      (Array(@profile.preferred_buddy_times) & Array(candidate_profile.preferred_buddy_times))
        .map { |slot| slot.humanize }
    end

    def same_gym_match?(candidate_profile)
      @profile.home_gym_name.present? &&
        candidate_profile.home_gym_name.present? &&
        @profile.home_gym_name == candidate_profile.home_gym_name
    end

    def same_city_match?(candidate_profile)
      @profile.home_city.present? &&
        candidate_profile.home_city.present? &&
        @profile.home_city == candidate_profile.home_city
    end

    def schedule_score(slots_a, slots_b)
      total_overlap = 0
      slots_a.each do |slot_a|
        slots_b.each do |slot_b|
          total_overlap += slot_a.overlap_minutes(slot_b)
        end
      end

      maximum = 7 * 60 * 4.0
      (total_overlap / maximum).clamp(0.0, 1.0)
    end

    def jaccard_similarity(list_a, list_b)
      set_a = Array(list_a).map(&:downcase).to_set
      set_b = Array(list_b).map(&:downcase).to_set
      return 0.0 if set_a.empty? && set_b.empty?

      (set_a & set_b).size.to_f / (set_a | set_b).size
    end

    def next_overlap_windows(candidate_slots)
      windows = []
      start_date = Date.current

      WINDOW_LOOKAHEAD_DAYS.times do |offset|
        date = start_date + offset.days
        day_slots = slots_for_day(@availability, date.wday)
        candidate_day_slots = slots_for_day(candidate_slots, date.wday)

        day_slots.each do |slot_a|
          candidate_day_slots.each do |slot_b|
            overlap = overlap_range(slot_a, slot_b)
            next if overlap.nil?

            windows << {
              start_at: date.to_time.change(hour: overlap[:start_hour], min: overlap[:start_min]),
              end_at: date.to_time.change(hour: overlap[:end_hour], min: overlap[:end_min])
            }
            return windows if windows.size >= MAX_WINDOWS
          end
        end
      end

      windows
    end

    def slots_for_day(slots, dow)
      slots.select { |slot| slot.dow == dow }
    end

    def overlap_range(slot_a, slot_b)
      overlap_start = [slot_a.start_min, slot_b.start_min].max
      overlap_end = [slot_a.end_min, slot_b.end_min].min
      return nil if overlap_end <= overlap_start

      {
        start_hour: overlap_start / 60,
        start_min: overlap_start % 60,
        end_hour: overlap_end / 60,
        end_min: overlap_end % 60
      }
    end
  end
end
