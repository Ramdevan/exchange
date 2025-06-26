# Load the rails application

require File.expand_path('../application', __FILE__)

require 'daemons/amqp_daemon'


# Initialize the rails application
Exchange::Application.initialize!
