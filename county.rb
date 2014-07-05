require_relative 'district'
require_relative 'models'

YEAR_DELTA = 5

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def average
    sum / size
  end
end

class County
  def initialize query
    @query = query
    @name = find_closest_county
    @districts = districts
    @nhs_trusts = nhs_trusts
    @alcohol = find_closest_alcohol
  end

  def output
    {
      query: @query,
      alcohol: @alcohol,
      name: @name,
      nhs_trusts: @nhs_trusts,
      districts: @districts
    }
  end

  def flat_output req_year
    req_year = req_year.to_i

    data = {
      "year" => req_year
    }
    %w{drug_use drunk_behaviour}.each do |k|
      data["perception_#{k}"] = @districts.map { |d| d[:perception][k.to_sym] }.average
    end

    indicators = @districts.map { |d| d[:lape].keys }.flatten.uniq

    indicator_groups = indicators.map do |indicator|
      groups = @districts.map { |d| d[:lape][indicator].map { |i| i[:group] } }
      groups.flatten!
      groups.uniq!

      [indicator, groups]
    end
    indicator_groups = Hash[indicator_groups]

    # Years we need
    years = (req_year-YEAR_DELTA+1).upto(req_year).to_a

    indicator_groups.each do |indicator, groups|
      groups.each do |group|
        group_indicator_results = []
        # Predict inside each district
        @districts.each do |district|
          district_indicator_results = {}
          district[:lape][indicator].each do |result|
            next unless result[:group] == group
            # Average year
            year = result[:date].map(&:to_i).average.to_i
            next unless years.include? year

            district_indicator_results[year] = result[:value]
          end

          # Predict any years we need not present
          no_results = true
          years.each do |year|
            next if district_indicator_results.include? year
            no_results = false

            # Closest two results
            closest_years = district_indicator_results.keys.sort_by { |y| (year-y).abs }
            closest = district_indicator_results[closest_years[0]]
            closest_2 = district_indicator_results[closest_years[1]]

            if closest_2.nil?
              district_indicator_results[year] = closest
            elsif closest.nil?
              raise "No results for #{year}: #{indicator}".inspect
            else
              # TODO
              # district_indicator_results[year] = 2*closest - closest_2
              district_indicator_results[year] = closest
            end

            raise district_indicator_results.inspect if district_indicator_results.empty?
          end
          group_indicator_results << district_indicator_results
        end

        # Average for all districts
        group_indicator_results = years.map do |year|
          raise group_indicator_results.inspect if group_indicator_results.empty?
          values = group_indicator_results.map { |results| results[year] }.average
          # year delta
          [req_year-year, values]
        end
        group_indicator_results = Hash[group_indicator_results]

        # Key for group and indicator
        key = (group.nil? ? "" : group + "_") + indicator

        group_indicator_results.each do |year_delta, value|
          data[key + "_" + year_delta.to_s] = value
        end
      end
    end

    alcohol_costs = {}
    @nhs_trusts.each do |trust|
      trust[:alcohol_costs].each do |costs|
        costs[:cost].each do |key, value|
          alcohol_costs[key] = [] unless alcohol_costs.include? key
          alcohol_costs[key] << value
        end
      end
    end
    alcohol_costs.each do |key, values|
      data["alcohol_cost_#{key}"] = values.sum
    end

    Hash[data.keys.sort.map { |k| [k, data[k]] }]
  end

  def find_closest_county
    sql = "SELECT name FROM county_regions WHERE name ~* '#{@query}';"
    DataMapper.repository(:default).adapter.select(sql).first
  end

  def find_closest_alcohol
    sql = "SELECT * FROM alcohol_counties WHERE name ~* '#{@query}';"
    DataMapper.repository(:default).adapter.select(sql).map { |a| a }
  end

  def districts
    sql = "SELECT district_borough_unitary_region.name FROM county_regions, district_borough_unitary_region WHERE ST_CONTAINS(county_regions.geom, district_borough_unitary_region.geom) AND county_regions.name = '#{@name}';"
    DataMapper.repository(:default).adapter.select(sql).map do |district|
      # Ends in District or Boro
      district.gsub! " District", ""
      district.gsub! " Boro", ""
      district.gsub! /\ \([a-zA-Z ]*\)/, ""
      district.gsub! " London", "" unless district.include? "of London"
      district.gsub! "City and County of the ", ""

      d = District.new district
      d.output
    end
  end

  def nhs_trusts
    nhs_trust_name = @name.gsub " County", ""
    nhs_trust_name = "London" if nhs_trust_name == "Greater London Authority"
    sql = "SELECT code FROM organisations WHERE address_line_5 ~* '#{nhs_trust_name}';"
    codes = DataMapper.repository(:default).adapter.select(sql)
    codes.map do |code|
      o = Organisation.first code: code
      o.output
    end
  end

  def self.new_from_district district
    sql = "SELECT county_regions.name FROM county_regions, district_borough_unitary_region WHERE ST_CONTAINS(county_regions.geom, district_borough_unitary_region.geom) AND district_borough_unitary_region.name ~* '#{district}';"
    result = DataMapper.repository(:default).adapter.select(sql).first
    return nil if result.nil?
    County.new result
  end
end
