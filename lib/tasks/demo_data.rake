namespace :spotmate do
  desc "Create demo users, profiles, availability, and sample matches"
  task seed_demo: :environment do
    raise "Faker is required (bundle exec rake spotmate:seed_demo)" unless defined?(Faker)

    gyms = [
      { name: "PureGym Belfast City", city: "Belfast", lat: 54.5975, lng: -5.9301 },
      { name: "Queen's PEC", city: "Belfast", lat: 54.5848, lng: -5.9346 },
      { name: "Ulster Sports Centre", city: "Belfast", lat: 54.6002, lng: -5.9168 },
      { name: "Better Gym Lisburn", city: "Lisburn", lat: 54.5131, lng: -6.0317 },
      { name: "Anytime Fitness Ballymena", city: "Ballymena", lat: 54.8639, lng: -6.2760 }
    ]

    genders = %w[female male non_binary prefer_not_say]
    times_of_day = Profile::TIME_OF_DAY_OPTIONS
    days = Profile::BUDDY_DAY_OPTIONS
    goals = Profile::GOAL_OPTIONS
    travel = Profile.travel_preferences.keys
    bands = Profile.experience_bands.keys

    count = ENV.fetch("COUNT", "12").to_i
    target_email = ENV["EMAIL"]
    created_users = []

    count.times do |i|
      email = "demo#{Time.now.to_i}#{i}@spotmate.test"
      user = User.create!(
        email: email,
        password: "Password123!",
        name: Faker::Name.first_name
      )

      gender = genders.sample
      gym = gyms.sample
      age = rand(18..35)
      min_age = [age - rand(2..6), 16].max
      max_age = [age + rand(2..8), 100].min

      user.create_profile!(
        age: age,
        gender: gender,
        home_gym_name: gym[:name],
        home_city: gym[:city],
        gym_latitude: gym[:lat],
        gym_longitude: gym[:lng],
        travel_preference: travel.sample,
        experience_band: bands.sample,
        goals: goals.sample(rand(2..4)),
        preferred_partner_age_min: min_age,
        preferred_partner_age_max: max_age,
        preferred_buddy_days: days.sample(rand(2..4)),
        preferred_buddy_times: times_of_day.sample(rand(1..3)),
        women_only: gender != "male" && [true, false].sample
      )

      rand(2..3).times do
        dow = rand(0..6)
        start_hour = rand(6..20)
        start_min = start_hour * 60
        end_min = start_min + rand(60..120)
        user.availability_slots.create!(dow: dow, start_min: start_min, end_min: end_min)
      end

      created_users << user
    end

    host = if target_email.present?
             User.find_by(email: target_email)
           else
             User.order(created_at: :asc).first
           end

    if host.nil?
      puts "No host user found. Provide EMAIL=you@example.com to seed matches for your account."
      return
    end

    partners = User.where.not(id: host.id).limit(2)
    if partners.size >= 2
      partners.each_with_index do |partner, index|
        match = Match.find_or_initialize_by(user_a: host, user_b: partner)
        match.status ||= :accepted
        match.score ||= [0.86, 0.79][index] || 0.8
        match.save!

        MatchDecision.find_or_create_by!(match: match, user: host, decision: :accepted)
        MatchDecision.find_or_create_by!(match: match, user: partner, decision: :accepted)

        Booking.find_or_create_by!(
          match: match,
          creator: host,
          start_at: (index + 2).days.from_now.change(hour: 18, min: 0),
          end_at: (index + 2).days.from_now.change(hour: 19, min: 0)
        )
      end
    end

    if host.availability_slots.none?
      home_location = host.profile&.home_gym_name.presence || "Home gym"
      [
        { dow: 1, start_min: 18 * 60, end_min: 19 * 60 + 30 },
        { dow: 3, start_min: 18 * 60, end_min: 20 * 60 },
        { dow: 5, start_min: 10 * 60, end_min: 11 * 60 + 30 }
      ].each do |slot|
        host.availability_slots.create!(slot.merge(location_name: home_location))
      end
    end

    if host.workout_logs.none?
      host.workout_logs.create!(
        date: Date.current - 1,
        kind: :strength,
        payload_json: { exercises: ["Squat 3x5", "Bench 3x5", "Row 3x8"] }
      )
      host.workout_logs.create!(
        date: Date.current - 3,
        kind: :conditioning,
        payload_json: { exercises: ["5k run", "Intervals 8x400m"] }
      )
    end

    partners.each_with_index do |partner, index|
      next if partner.workout_logs.where(shared_with_buddies: true).exists?

      log = partner.workout_logs.create!(
        date: Date.current - (index + 1),
        kind: :strength,
        title: "Buddy session",
        exercises: ["Deadlift 3x5", "Pull-ups 3x8", "Core circuit"],
        shared_with_buddies: true,
        contains_pr: [true, false].sample
      )
      WorkoutComment.create!(workout_log: log, author: host, body: "Nice work! 🔥")
      WorkoutKudo.create!(workout_log: log, giver: host)
    end

    if host.prs.none?
      [
        { exercise: "Squat", value: 100, unit: "kg", date: Date.current - 10 },
        { exercise: "Bench", value: 70, unit: "kg", date: Date.current - 8 },
        { exercise: "Deadlift", value: 120, unit: "kg", date: Date.current - 6 },
        { exercise: "5k run", value: 24.5, unit: "min", date: Date.current - 4 }
      ].each do |pr|
        host.prs.create!(pr)
      end
    end

    puts "Created #{created_users.size} demo users."
    puts "Seeded #{partners.size} accepted matches for #{host.email}."
  end
end
