require_relative 'models'
require_relative 'county'
require 'libsvm'

FINAL_YEAR = 2012
TRAIN = 10
TEST = 0
LIMIT = TRAIN + TEST

X = []
Y = []
counties = []

keys = []

# TODO Normalise y by pop
# TODO Intervention cost as X input

sql = "SELECT name FROM county_regions LIMIT #{LIMIT};"
results = DataMapper.repository(:default).adapter.select(sql)
results.shuffle!
results.each do |name|
  puts "County: #{name}"
  county = County.new name
  resp = county.flat_output FINAL_YEAR

  x = []
  y = nil

  resp.each do |key, value|
    key = key.to_s
    value = value.to_f

    if key == "alcohol_cost_expected" or key == "alcohol_cost_unit"
      next
    elsif key == "admission_episodes_0"
      y = value
    # elsif key == "alcohol_cost_actual"
      # y = value
    else
      puts key
      x << value
    end
  end

  X << x
  Y << y
  counties << name
end

X.shuffle!

Xtrain = X[0...TRAIN].map { |ary| Libsvm::Node.features(ary) }
Ytrain = Y[0...TRAIN]
countiestrain = counties[0...TRAIN]
Xtest = X[TRAIN...TRAIN+TEST].map { |ary| Libsvm::Node.features(ary) }
Ytest = Y[TRAIN...TRAIN+TEST]
countiestest = Y[TRAIN...TRAIN+TEST]

problem = Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size = 100
parameter.eps = 1
parameter.c = 100

problem.set_examples(Ytrain, Xtrain)
$model = Libsvm::Model.train(problem, parameter)

# Xtest.zip(Ytest, countiestest).map do |x, y, county|
  # puts county
  # pred = model.predict(x)
  # puts ((pred-y).abs)/y
# end


class PredictCounty
  def initialize county_name
    county = County.new county_name
    resp = county.flat_output 2013

    x = []
    y = nil
    @ac_ind = 0
    resp.each do |key, value|
      key = key.to_s
      value = value.to_f

      @ac_ind = x.count if key == "alcohol_cost_actual"

      if key == "alcohol_cost_expected" or key == "alcohol_cost_unit"
        next
      elsif key == "admission_episodes_0"
        y = value
      else
        x << value
      end
    end
    @y = y
    @x = x
    @cy = $model.predict(Libsvm::Node.features(@x))
  end

  def predict num
    puts num.inspect
    x = @x.clone
    x[9] = num
    {
      current: @cy,
      predicted: $model.predict(Libsvm::Node.features(x)),
      from_data: @y
    }
  end
end
