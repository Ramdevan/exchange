module Private
  module Withdraws
    class RipplesController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
