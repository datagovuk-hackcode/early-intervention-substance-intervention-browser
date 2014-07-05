require_relative 'models'

class District
  def initialize name
    @name = (name == "City of Westminster") ? "Westminster" : name
    @name.gsub! ".", ""

    @perception = PerceptionDistrict.first :district.like => "%#{@name.gsub "'", ""}%"

    @lape = LAPELocalAuthority.first :name.like => "%#{@name}%"
  end

  def output
    {
      name: @name,
      perception: @perception.output,
      lape: @lape.output
    }
  end
end
