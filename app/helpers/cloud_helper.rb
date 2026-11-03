module CloudHelper
  # Self-hosted installs have no cloud/ partials; the private hosted engine supplies them (docs/business/open-core.md).
  def cloud_slot(name, **locals)
    render("cloud/#{name}", **locals) if lookup_context.exists?(name, [ "cloud" ], true)
  end
end
