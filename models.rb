require 'data_mapper'
require 'dm-is-reflective'
require 'open-uri/cached'
require 'json'

DATA_ROOT = "/home/harry/src/social_intervention/data"

DataMapper.setup(:default, "postgres://harry@localhost/social_intervention")

class Cost
  include DataMapper::Resource

  property :id, Serial
  property :unit_cost, Decimal
  property :actual_cost, Decimal
  property :expected_cost, Decimal
  property :activity, Decimal
  property :bed_days, Decimal
  property :mean, Decimal
  property :mapping_pot, String

  belongs_to :service
  belongs_to :organisation
  belongs_to :department
  belongs_to :currency
end

class Department
  include DataMapper::Resource
  property :code, Text, key: true
  property :name, Text
  has n, :costs
end

class Currency
  include DataMapper::Resource
  property :code, Text, key: true
  property :name, Text
  has n, :costs

  def self.alcohol_currencies
    %w{Alcohol Liver Kidney}.map { |s| Currency.all(:name.like => "%#{s}%") }.flatten
  end
end

class Service
  include DataMapper::Resource
  property :code, Text, key: true
  property :name, Text
  has n, :costs

  def self.alcohol_service
    Service.first(code: 'DAS')
  end
end

class AlcoholCounty
  include DataMapper::Resource
  property :name, Text, key: true
  property :date, Date, key: true
  property :no_in_treatment, Decimal
  property :new_presentations, Decimal
  property :no_in_treatment_ytd, Decimal
  property :discharges, Decimal

  def output
    {
      date: date,
      no_in_treatment: no_in_treatment,
      new_presentations: new_presentations,
      no_in_treatment_ytd: no_in_treatment_ytd,
      discharges: discharges
    }
  end
end

class PerceptionDistrict
  include DataMapper::Resource
  property :district, Text, key: true
  property :perception_drug_use, Decimal
  property :perception_drunk_behaviour, Decimal

  def output
    {
      drug_use: perception_drug_use.to_f,
      drunk_behaviour: perception_drunk_behaviour.to_f
    }
  end
end

class Organisation
  include DataMapper::Resource
  property :code, Text, key: true
  property :name, Text
  property :national_grouping_code, Text
  property :high_level_health_authority, Text
  property :address_line_1, Text
  property :address_line_2, Text
  property :address_line_3, Text
  property :address_line_4, Text
  property :address_line_5, Text
  property :postcode, Text
  property :open_date, Text
  property :close_date, Text

  has n, :costs

  def alcohol_costs
    costs = Currency.alcohol_currencies.map { |currency| self.costs(currency: currency) }.flatten
    costs.map do |cost|
      {
        cost: {
          actual: cost.actual_cost.to_f,
          expected: cost.expected_cost.to_f,
          unit: cost.unit_cost.to_f
        }
      }
    end
  end

  def output
    {
      name: self.name,
      address: ([self.address_line_1,self.address_line_2,self.address_line_3,self.address_line_4,self.address_line_5].reject(&:nil?).reject(&:empty?) << self.postcode).join(", "),
      alcohol_costs: self.alcohol_costs
    }
  end
end

class LAPELocalAuthority
  include DataMapper::Resource
  property :name, Text, key: true
  property :male_months_lost_2004_2006, Float
  property :male_months_lost_2005_2007, Float
  property :male_months_lost_2006_2008, Float
  property :male_months_lost_2007_2009, Float
  property :male_months_lost_2008_2010, Float
  property :female_months_lost_2004_2006, Float
  property :female_months_lost_2005_2007, Float
  property :female_months_lost_2006_2008, Float
  property :female_months_lost_2007_2009, Float
  property :female_months_lost_2008_2010, Float
  property :male_specific_mortality_rate_2008_2010, Float
  property :male_specific_mortality_rate_2004_2006, Float
  property :male_specific_mortality_rate_2005_2007, Float
  property :male_specific_mortality_rate_2006_2008, Float
  property :male_specific_mortality_rate_2007_2009, Float
  property :female_specific_mortality_rate_2008_2010, Float
  property :female_specific_mortality_rate_2004_2006, Float
  property :female_specific_mortality_rate_2005_2007, Float
  property :female_specific_mortality_rate_2006_2008, Float
  property :female_specific_mortality_rate_2007_2009, Float
  property :male_chronic_liver_disease_mortality_rate_2008_2010, Float
  property :female_chronic_liver_disease_mortality_rate_2008_2010, Float
  property :male_attributable_mortality_rate_2010, Float
  property :male_attributable_mortality_rate_2006, Float
  property :male_attributable_mortality_rate_2007, Float
  property :male_attributable_mortality_rate_2008, Float
  property :male_attributable_mortality_rate_2009, Float
  property :female_attributable_mortality_rate_2010, Float
  property :female_attributable_mortality_rate_2006, Float
  property :female_attributable_mortality_rate_2007, Float
  property :female_attributable_mortality_rate_2008, Float
  property :under_18s_specific_hospital_admissions_rate_2004_2007, Float
  property :under_18s_specific_hospital_admissions_rate_2005_2008, Float
  property :under_18s_specific_hospital_admissions_rate_2006_2009, Float
  property :under_18s_specific_hospital_admissions_rate_2007_2010, Float
  property :under_18s_specific_hospital_admissions_rate_2008_2011, Float
  property :male_specific_hospital_admissions_rate_2006_2007, Float
  property :male_specific_hospital_admissions_rate_2007_2008, Float
  property :male_specific_hospital_admissions_rate_2008_2009, Float
  property :male_specific_hospital_admissions_rate_2009_2010, Float
  property :female_specific_hospital_admissions_rate_2006_2007, Float
  property :female_specific_hospital_admissions_rate_2007_2008, Float
  property :female_specific_hospital_admissions_rate_2008_2009, Float
  property :female_specific_hospital_admissions_rate_2009_2010, Float
  property :male_attributable_hospital_admissions_rate_2006_2007, Float
  property :male_attributable_hospital_admissions_rate_2007_2008, Float
  property :male_attributable_hospital_admissions_rate_2008_2009, Float
  property :male_attributable_hospital_admissions_rate_2009_2010, Float
  property :female_attributable_hospital_admissions_rate_2006_2007, Float
  property :female_attributable_hospital_admissions_rate_2007_2008, Float
  property :female_attributable_hospital_admissions_rate_2008_2009, Float
  property :female_attributable_hospital_admissions_rate_2009_2010, Float
  property :admission_episodes_2006_2007, Float
  property :admission_episodes_2007_2008, Float
  property :admission_episodes_2008_2009, Float
  property :admission_episodes_2009_2010, Float
  property :admission_episodes_rate_2010_2011, Float
  property :attributable_crime_rate_2007_2008, Float
  property :attributable_crime_rate_2008_2009, Float
  property :attributable_crime_rate_2009_2010, Float
  property :attributable_crime_rate_2010_2011, Float
  property :attributable_crime_rate_2011_2012, Float
  property :attributable_violent_crime_rate_2007_2008, Float
  property :attributable_violent_crime_rate_2008_2009, Float
  property :attributable_violent_crime_rate_2009_2010, Float
  property :attributable_violent_crime_rate_2010_2011, Float
  property :attributable_violent_crime_rate_2011_2012, Float
  property :attributable_violent_crime_rate_2007_2008, Float
  property :attributable_sexual_crime_rate_2008_2009, Float
  property :attributable_sexual_crime_rate_2009_2010, Float
  property :attributable_sexual_crime_rate_2010_2011, Float
  property :attributable_sexual_crime_rate_2011_2012, Float

  def output
    attrs = attributes.tap { |attr| attr.delete(:name) }.map do |attr, val|
      group, key, date = attr.to_s.match(/(male|female|under_18s)?_?([a-zA-Z_]+)_((20\d\d)_?(20\d\d)?)/).captures
      date = date.split "_"
      date = [date] if date.is_a? Integer
      [group, key, date]
    end

    keys = attrs.map { |attr| attr[1] }.uniq
    d = keys.map do |key|
      results = attrs.select { |attr| attr[1] == key }
      results.map! do |group, key2, date|
        date_string = date.join("_")
        {
          group: group,
          date: date,
          value: attributes[((group.nil? ? "" : "#{group}_") + key + "_" + date_string).to_sym]
        }.tap { |attr| attr.delete(:group) if attr[:group].nil? }
      end
      [key, results]
    end

    Hash[d]
  end
end

DataMapper.finalize
