module APIv2
  module NamedParams
    extend ::Grape::API::Helpers

    params :auth do
      requires :access_key, type: String,  desc: "Access key."
      requires :tonce,      type: Integer, desc: "Tonce is an integer represents the milliseconds elapsed since Unix epoch."
      requires :signature,  type: String,  desc: "The signature of your request payload, generated using your secret key."
    end

    params :market do
      requires :market, type: String, values: ::Market.all.map(&:id), desc: ::APIv2::Entities::Market.documentation[:id]
    end

    params :order do
      requires :side,   type: String, values: %w(sell buy), desc: ::APIv2::Entities::Order.documentation[:side]
      requires :volume, type: String, desc: ::APIv2::Entities::Order.documentation[:volume]
      optional :price,  type: String, desc: ::APIv2::Entities::Order.documentation[:price]
      optional :ord_type, type: String, values: %w(limit market), desc: ::APIv2::Entities::Order.documentation[:type]
    end

    params :order_id do
      requires :id, type: Integer, desc: ::APIv2::Entities::Order.documentation[:id]
    end

    params :trade_filters do
      optional :limit,     type: Integer, range: 1..1000, default: 50, desc: 'Limit the number of returned trades. Default to 50.'
      optional :timestamp, type: Integer, desc: "An integer represents the seconds elapsed since Unix epoch. If set, only trades executed before the time will be returned."
      optional :from,      type: Integer, desc: "Trade id. If set, only trades created after the trade will be returned."
      optional :to,        type: Integer, desc: "Trade id. If set, only trades created before the trade will be returned."
      optional :order_by,     type: String, values: %w(asc desc), default: 'desc', desc: "If set, returned trades will be sorted in specific order, default to 'desc'."
    end

    params :documents do
      requires :first_name, type: String,  desc: "Document name."
      requires :last_name, type: String,  desc: "Document name."
      requires :id_document_type, type: String, desc: "Select type of document(id_card, passport, driver_license)"
      requires :id_document_number, type: String,  desc: "Document number (ex: Driving license number)"
      requires :id_bill_type,  type: String,  desc: "Select type of document(bank_statement, tax_bill)"
      optional :birth_date, type: String, desc: "Select your Birth date, as per records"
      optional :address, type: String, desc: "Your address"
      optional :city, type: String, desc: "Your current city"
      optional :country, type: String, desc: "Your Country"
      optional :zipcode, type: String, desc: "Enter your Postal code"
    end

  end
end
