Exchange::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_files = true

  # Compress JavaScripts and CSS.
  # TODO: Funds page not getting loaded due to some conflict with Uglifier and landing page JS.
  # TODO: Need to find proper fix and uncomment uglifier.
  # config.assets.js_compressor = Uglifier.new(:mangle => false)
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :memory_store
  config.cache_store = :redis_store, ENV['REDIS_URL']

  config.session_store :redis_store, :key => '_exchange_session', :expire_after => ENV['SESSION_EXPIRE'].to_i.minutes

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  config.assets.precompile += %w( funds.js market.js market.css admin.js admin.css html5.js api_v2.css api_v2.js .svg .eot .woff .ttf )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: ENV["URL_HOST"], protocol: ENV['URL_SCHEMA'] }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    port:           ENV["MAILGUN_PORT"],
    domain:         ENV["MAILGUN_DOMAIN"],
    address:        ENV["MAILGUN_ADDRESS"],
    user_name:      ENV["MAILGUN_USERNAME"],
    password:       ENV["MAILGUN_PASSWORD"],
    authentication: ENV["MAILGUN_AUTHENTICATION"],
    enable_starttls_auto: ENV["MAILGUN_ENABLE_STARTTLS_AUTO"]
    #port:           ENV["SMTP_PORT"],
    #domain:         ENV["SMTP_DOMAIN"],
    #address:        ENV["SMTP_ADDRESS"],
    #user_name:      ENV["SMTP_USERNAME"],
    #password:       ENV["SMTP_PASSWORD"],
    #authentication: ENV["SMTP_AUTHENTICATION"],
    #enable_starttls_auto: ENV["SMTP_ENABLE_STARTTLS_AUTO"]
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.default_timezone = :local

  config.middleware.insert_before Rack::Runtime, Middleware::Security
  config.middleware.use ExceptionNotification::Rack,
    email: {
      deliver_with: :deliver,
      email_prefix: "[#{ENV["URL_HOST"]}]",
      sender_address: %{"notifier" <#{ENV['EXCEPTION_SENDER_ADDRESS']}>},
      exception_recipients: ENV['EXCEPTION_RECIPIENTS'].split
    },
    error_grouping: true

end
