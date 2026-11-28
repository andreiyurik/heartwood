class DateReadingsController < ApplicationController
  def show
    @frame = params[:frame].to_s[/\A\w+\z/] or return head(:bad_request)
    @text = params[:date].to_s.strip
    @date = FuzzyDate.parse(@text)
  end
end
