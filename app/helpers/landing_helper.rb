module LandingHelper
  FOUNDER_PHOTO = "landing/founder.jpg"

  def founder_portrait(name)
    if Rails.application.assets.load_path.find(FOUNDER_PHOTO)
      image_tag FOUNDER_PHOTO, alt: "", class: "avatar landing-letter__photo"
    else
      initials_avatar name, class: "landing-letter__photo"
    end
  end

  def landing_screenshot(name, alt:)
    { "only-light" => "", "only-dark" => ".dark" }.map do |scheme, suffix|
      image_tag "landing/#{name}.#{I18n.locale}#{suffix}.png", alt:, class: scheme, loading: "lazy", width: 940, height: 917
    end.then { |images| safe_join images }
  end
end
