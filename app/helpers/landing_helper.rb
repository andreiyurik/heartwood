module LandingHelper
  FOUNDER_PHOTO = "landing/founder.jpg"

  def founder_portrait(name)
    if Rails.application.assets.load_path.find(FOUNDER_PHOTO)
      image_tag FOUNDER_PHOTO, alt: "", class: "avatar landing-letter__photo"
    else
      initials_avatar name, class: "landing-letter__photo"
    end
  end

  def demo_url
    landing = Rails.configuration.x.landing
    landing.demo_url || (ShareLink.of_owner(landing.demo_owner).first&.then { shared_tree_path(it.token) } if landing.demo_owner)
  end

  def landing_screenshot(name, alt:)
    { "only-light" => "", "only-dark" => ".dark" }.map do |scheme, suffix|
      image_tag "landing/#{name}.#{I18n.locale}#{suffix}.png", alt:, class: scheme, loading: "lazy", width: 940, height: 917
    end.then { |images| safe_join images }
  end
end
