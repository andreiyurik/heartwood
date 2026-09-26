module ApplicationHelper
  SECTIONS = {
    "people" => %w[people],
    "tree"   => %w[clan_trees trees],
    "map"    => %w[maps]
  }.freeze

  def icon_tag(name, **options)
    classes = [ "icon", "icon--#{name}", options.delete(:class) ].compact.join(" ")
    tag.span class: classes, "aria-hidden": true, **options
  end

  def page_title(name)
    content_for :title, [ name, Current.tree&.name, "Heartwood" ].compact.join(" · ")
    content_for :page, name
  end

  def back_link(path)
    content_for :back do
      link_to path, class: "btn btn--circle back" do
        icon_tag("arrow-left") + tag.span(t("nav.back"), class: "for-screen-reader")
      end
    end
  end

  def icon_link_to(name, label, path, **options)
    link_to path, class: class_names("btn btn--circle", options.delete(:class)), **options do
      icon_tag(name) + tag.span(label, class: "for-screen-reader")
    end
  end

  def icon_button_to(name, label, path, **options)
    button_to path, class: class_names("btn btn--circle", options.delete(:class)), **options do
      icon_tag(name) + tag.span(label, class: "for-screen-reader")
    end
  end

  def blank_tree?
    Current.tree.people.none?
  end

  def full_bleed
    content_for :body_class, "full-bleed"
  end

  def section_link(section, path)
    current = SECTIONS.fetch(section).include?(controller_name)
    link_to t("nav.#{section}"), path, aria: { current: ("page" if current) }
  end

  # Whether the current membership can add/edit/delete tree data — viewers can't.
  # See [[collaboration]]. Controller-level require_can_edit is the actual
  # security boundary; this just keeps pointless affordances out of the view.
  def can_edit?
    Current.membership&.can_edit?
  end
end
