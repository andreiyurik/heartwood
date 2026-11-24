class FeedbacksController < ApplicationController
  MAX_LENGTH = 2000

  before_action :require_operator_address
  rate_limit to: 5, within: 1.hour, only: :create, with: -> { redirect_to root_path, alert: t("flash.try_later") }

  def new
    @page = page_from(request.referer)
  end

  def create
    @page = page_from(feedback_params[:page])
    body  = feedback_params[:body].to_s.strip

    if body.present? && body.length <= MAX_LENGTH
      # Sent now, not queued: the letter's words never sit in the job table or its log.
      FeedbackMailer.with(user: Current.user, body: body, page: @page, locale: I18n.locale.to_s).sent.deliver_now
      redirect_to @page || root_path, notice: t("feedbacks.sent")
    else
      @body = body
      render :new, status: :unprocessable_entity
    end
  end

  private
    def require_operator_address
      head :not_found if Rails.configuration.x.operator[:email].blank?
    end

    def feedback_params = params.expect(feedback: %i[body page])

    # Only a page of this site, as a path: nothing of another site, no host, no fragment.
    def page_from(url)
      return unless (url = url_from(url))
      uri = URI.parse(url)
      path = [ uri.path, uri.query ].compact.join("?")
      path unless path.start_with?(new_feedback_path)
    rescue URI::InvalidURIError
      nil
    end
end
