module Private
  module Withdraws
    class LinksController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
