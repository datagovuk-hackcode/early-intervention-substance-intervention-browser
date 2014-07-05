require 'grape'
require_relative 'county'
require_relative 'predict'

class API < Grape::API
  format :json

  get '/predict/:name/:cost' do
    pc = PredictCounty.new params[:name]
    pc.predict params[:cost].to_f
  end

  resource :counties do
    params do
      requires :name, type: String, desc: "County name"
    end
    route_param :name do
      get do
        county = County.new params[:name]
        county.output
      end

      route_param :year do
        get do
          county = County.new params[:name]
          county.flat_output params[:year]
        end
      end
    end
  end

  resource :districts do
    params do
      requires :name, type: String, desc: "District name"
    end
    route_param :name do
      get do
        county = County.new_from_district params[:name]
        county.output
      end
    end
  end
end
