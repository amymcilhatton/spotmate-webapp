Devise.setup do |config|
  # Configure the e-mail address used in Devise::Mailer.
  config.mailer_sender = "example@email.com"

  # Load and configure the ORM. This defines the `devise` model macro.
  require "devise/orm/active_record"

  # Navigational formats defines which formats are considered navigational.
  # The default is "*/*", but you can set it to an array of MIME types.
  # config.navigational_formats = ["*/*", :html, :turbo_stream]
end
