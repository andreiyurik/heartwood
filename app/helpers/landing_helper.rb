module LandingHelper
  FOUNDER_PHOTO = "landing/founder.jpg"

  def founder_portrait(name)
    if Rails.application.assets.load_path.find(FOUNDER_PHOTO)
      image_tag FOUNDER_PHOTO, alt: name, class: "avatar landing-letter__photo"
    else
      initials_avatar name, class: "landing-letter__photo"
    end
  end
end
