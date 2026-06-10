# Idempotent seeds. Run with: bin/rails db:seed
#
# Создаёт пользователя по умолчанию для локальной разработки.
# Смените пароль после первого входа.

if Rails.env.local?
  user = User.find_or_create_by!(email_address: "you@example.com") do |u|
    u.password = "heartwood"
  end
  puts "Seed-пользователь: #{user.email_address} / пароль: heartwood"

  # Небольшая примерная семья, чтобы дерево не было пустым при первом запуске.
  if Person.none?
    иван   = Person.create!(given_names: "Иван",   surname: "Дубров", sex: "M")
    мария  = Person.create!(given_names: "Мария",  surname: "Дуброва", sex: "F")
    сергей = Person.create!(given_names: "Сергей", surname: "Дубров", sex: "M")

    иван.events.create!(kind: "BIRT", date_raw: "1948")
    мария.events.create!(kind: "BIRT", date_raw: "1952")
    сергей.events.create!(kind: "BIRT", date_raw: "1975")

    семья = Family.create!
    семья.partners << [ иван, мария ]
    семья.children << сергей

    puts "Seed-семья: #{Person.count} чел., #{Family.count} семья."
  end
end
