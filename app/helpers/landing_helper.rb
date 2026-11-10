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
    tag.picture do
      tag.source(srcset: image_path("landing/#{name}.#{I18n.locale}.dark.png"), media: "(prefers-color-scheme: dark)") +
        image_tag("landing/#{name}.#{I18n.locale}.png", alt:, loading: "lazy", width: 940, height: 917)
    end
  end
end
