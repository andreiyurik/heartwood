require "test_helper"
require "open3"
require "json"

class ProductionTest < ActiveSupport::TestCase
  test "a public install is served over HTTPS on its own host and mails from it" do
    config = production_config("APP_HOST" => "heartwood.example")

    assert config["force_ssl"]
    assert config["assume_ssl"]
    assert_includes config["hosts"], "heartwood.example"
    assert_equal({ "host" => "heartwood.example", "protocol" => "https" }, config["url_options"])
    assert_equal "Heartwood <no-reply@heartwood.example>", config["from"]
  end

  test "an install without a host stays on plain HTTP for any host" do
    config = production_config

    assert_not config["force_ssl"]
    assert_empty config["hosts"]
  end

  test "mail goes through the SMTP server from the environment" do
    config = production_config "APP_HOST" => "heartwood.example", "MAILER_FROM" => "Семья <tree@heartwood.example>",
      "SMTP_ADDRESS" => "smtp.yandex.ru", "SMTP_USERNAME" => "tree@heartwood.example", "SMTP_PASSWORD" => "secret"

    assert_equal "smtp", config["delivery_method"]
    assert_equal "Семья <tree@heartwood.example>", config["from"]
    assert_equal({ "address" => "smtp.yandex.ru", "port" => 587, "user_name" => "tree@heartwood.example",
      "password" => "secret", "authentication" => "plain", "tls" => false, "enable_starttls_auto" => true }, config["smtp"].except("open_timeout", "read_timeout"))
  end

  test "port 465 speaks TLS from the first byte instead of STARTTLS" do
    config = production_config "SMTP_ADDRESS" => "smtp.yandex.ru", "SMTP_PORT" => "465"

    assert_equal 465, config["smtp"]["port"]
    assert config["smtp"]["tls"]
    assert_not config["smtp"]["enable_starttls_auto"]
  end

  private
    def production_config(env = {})
      script = <<~RUBY
        mailer = Rails.configuration.action_mailer
        puts({ force_ssl: Rails.configuration.force_ssl, assume_ssl: Rails.configuration.assume_ssl,
          hosts: Rails.configuration.hosts.map(&:to_s), url_options: mailer.default_url_options,
          from: ApplicationMailer.default[:from], delivery_method: ApplicationMailer.delivery_method,
          smtp: mailer.smtp_settings }.to_json)
      RUBY
      blank = %w[ APP_HOST MAILER_FROM SMTP_ADDRESS SMTP_PORT SMTP_USERNAME SMTP_PASSWORD ].index_with(nil)
      env = blank.merge("RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1").merge(env)
      out, err, status = Open3.capture3(env, "bin/rails", "runner", script, chdir: Rails.root.to_s)
      assert status.success?, err
      JSON.parse(out.lines.last)
    end
end
