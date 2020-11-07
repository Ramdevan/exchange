module APIv2
  class SignupHistories < Grape::API
    helpers ::APIv2::NamedParams

    before { authenticate! }

    desc 'List your signup histories.', scopes: %w[ history ]
    params do
      optional :limit, type: Integer, range: 1..1000, default: 25, desc: "Set result limit."
      optional :page, type: Integer, values: 1..1000, default: 1, desc: "Page number (defaults to 1)."
    end
    get '/signup_histories' do
      histories = current_user.signup_histories
      present :signup_histories, histories, with: APIv2::Entities::SignupHistory
    end
  end
end