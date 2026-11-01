module LegalHelper
  def operator(detail)
    Rails.configuration.x.operator[detail].presence || tag.span(t("legal.missing"), class: "legal__missing")
  end
end
