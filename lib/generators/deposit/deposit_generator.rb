class DepositGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :code, :type => :string
  argument :symbol, :type => :string, :default => '#'

  def copy_initializer_file 
    template "models/model.rb.erb", "app/models/deposits/#{name.underscore}.rb"

    template "controllers/admin_controller.rb.erb", "app/controllers/admin/deposits/#{name.underscore.pluralize}_controller.rb"

    template "controllers/private_controller.rb.erb", "app/controllers/private/deposits/#{name.underscore.pluralize}_controller.rb"

    template "views/index.html.slim.erb", "app/views/admin/deposits/#{name.underscore.pluralize}/index.html.slim"

    template "funds/deposit.html.erb", "public/templates/funds/deposit_#{name.underscore}.html"

    # template "locales/client.en.yml.erb", "config/locales/#{name.underscore}_client.en.yml"
    # template "locales/server.en.yml.erb", "config/locales/#{name.underscore}_server.en.yml"

  end
end
