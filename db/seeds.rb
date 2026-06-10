# Idempotent seeds. Run with: bin/rails db:seed
#
# Creates a default sign-in for local development / self-host first run.
# Change the password after first login.

if Rails.env.local?
  user = User.find_or_create_by!(email_address: "you@example.com") do |u|
    u.password = "heartwood"
  end
  puts "Seed user ready: #{user.email_address} / password: heartwood"

  # A tiny example family so the tree isn't empty on first run.
  if Person.none?
    john = Person.create!(given_names: "John", surname: "Heartwood", sex: "M")
    jane = Person.create!(given_names: "Jane", surname: "Heartwood", sex: "F")
    kid  = Person.create!(given_names: "Sam", surname: "Heartwood", sex: "U")
    john.events.create!(kind: "BIRT", date_raw: "1950")
    family = Family.create!
    family.partners << [ john, jane ]
    family.children << kid
    puts "Seed family ready: #{Person.count} people, #{Family.count} family."
  end
end
