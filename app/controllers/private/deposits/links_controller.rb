module Private
  module Deposits
    class LinksController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
