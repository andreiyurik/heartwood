namespace :demo do
  desc "Build the landing's example tree under its own account and print its view link: OWNER=email"
  task rurikids: :environment do
    require Rails.root.join("db/demo/rurikids")

    email = ENV.fetch("OWNER")
    owner = User.find_or_create_by!(email_address: email) do |user|
      user.name = Rurikids::NAME
      user.password = SecureRandom.base58(32)
    end

    tree = Rurikids.build!(owner: owner)
    puts "DEMO_URL=/shared/#{tree.share_link.token}"
  end
end
