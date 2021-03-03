module Admin
  class CommissionsController < BaseController

    def index
    end

    def update_filters
      @dates = params['search']['date'].split(' - ')
      @currencies = params['search']['currencies'].reject(&:empty?)
      @versions = AccountVersion.admins.where(currency: @currencies).where(reason: 'trade_fees').created_between(@dates[0],@dates[1])
      @grouped_versions = @versions.created_between(@dates[0],@dates[1]).group_by(&:currency)
      respond_to do |format|
        format.js {render layout: false}
      end
    end
  end
end