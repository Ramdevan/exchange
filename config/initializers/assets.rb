# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'images')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'stylesheets')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'javascripts')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'stylesheets')

# Precompile additional assets.
Rails.application.config.assets.precompile += %w(
    .svg .eot .woff .ttf .png .jpg .gif
    favicon.png
    empty.css
    empty.js
  )

Rails.application.config.assets.precompile += %w(
    market.css
    empty.css
    application.css
  )

Rails.application.config.assets.precompile += %w(
    bootstrap-wysihtml5/b3.js
    bootstrap-wysihtml5/b3.css
    admin.js
    market.css
    empty.css
  )