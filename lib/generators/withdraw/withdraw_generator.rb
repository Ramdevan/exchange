class WithdrawGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :code, :type => :string
  argument :symbol, :type => :string, :default => '#'

  def copy_initializer_file
    template "models/model.rb.erb", "app/models/withdraws/#{name.underscore}.rb"

    template "controllers/private_controller.rb.erb", "app/controllers/private/withdraws/#{name.underscore.pluralize}_controller.rb"

    template "controllers/admin_controller.rb.erb", "app/controllers/admin/withdraws/#{name.underscore.pluralize}_controller.rb"

    template "views/private/new.html.slim.erb", "app/views/private/withdraws/#{name.underscore.pluralize}/new.html.slim"

    template "views/private/edit.html.slim.erb", "app/views/private/withdraws/#{name.underscore.pluralize}/edit.html.slim"

    template "views/admin/_table.html.slim.erb", "app/views/admin/withdraws/#{name.underscore.pluralize}/_table.html.slim"

    template "views/admin/index.html.slim.erb", "app/views/admin/withdraws/#{name.underscore.pluralize}/index.html.slim"

    template "views/admin/show.html.slim.erb", "app/views/admin/withdraws/#{name.underscore.pluralize}/show.html.slim"

    template "funds/withdraw.html.erb", "public/templates/funds/withdraw_#{name.underscore}.html"

    # remaining files
    template "instruction.html.erb", "instruction.html"
  end
end
