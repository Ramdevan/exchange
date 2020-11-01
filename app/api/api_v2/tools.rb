module APIv2
  class Tools < Grape::API
    desc 'Get server current time, in seconds since Unix epoch.'
    get "/timestamp" do
      ::Time.now.to_i
    end

    desc 'Get static web contents.'
    get "/static" do
      present :support_no, ENV['SUPPORT_PHONE']
      present :support_email, ENV['SUPPORT_MAIL']
      present :about, "#{ENV['URL_SCHEMA']}://#{ENV['URL_HOST']}/about"
    end

  end
end
