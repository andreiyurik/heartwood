module TimeHelper
  def local_datetime_tag(datetime, style: :time, **attributes)
    tag.time **attributes, datetime: datetime.iso8601, data: { local_time_target: style }
  end

  # The words are the fallback; the browser rewrites them, so a cached page never says a stale "5 minutes ago".
  def local_time_ago(datetime)
    local_datetime_tag datetime, style: :ago do
      t("local_time.ago", time: time_ago_in_words(datetime))
    end
  end
end
