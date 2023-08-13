require File.join(__dir__, 'therm')
require 'sinatra/base'
require 'prometheus/client'
require 'prometheus/client/formats/text'

class App < Sinatra::Base
  configure do
    set :server, :puma
    set :bind, '0.0.0.0'
    set :port, 9100
  end

  def initialize
    super
    @registry = Prometheus::Client.registry

    env_file = File.join(__dir__, 'config.yml')
    
    if File.exist?(env_file)
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
        puts "setting #{key.to_s}"
      end 
    else
      puts ""
      puts "Create a config.yml with the following format: "
      puts ""
      puts 'user: "user"'
      puts 'pass: "pass"'
      puts ""
      raise "Cannot Start without a config"
    end

    @user = ENV['THERM_USER']
    @pass = ENV['THERM_PASSWORD']

    @sensor = TempSensor.new(@user, @pass) #, @device_id)

    @up = @registry.gauge(:therm_up, 'Is device responding')
    @device_live = @registry.gauge(:therm_deviceLive, 'Is device live')
    @temperature = @registry.gauge(:therm_temperature, 'Current temperature')
    @heat_point = @registry.gauge(:therm_heat_point, 'Current heat trigger point')
    @cool_point = @registry.gauge(:therm_cool_point, 'Current cool trigger point')

    @status = @registry.gauge(:therm_status, 'Current system status')
    @heating = @registry.gauge(:heating, 'System heating')
    @cooling = @registry.gauge(:cooling, 'System cooling')
    @fan_status = @registry.gauge(:therm_fan_status, 'Current fan status')
    @humidity = @registry.gauge(:therm_humidity, 'Current Humidity')
  end

  get '/' do
    content_type :json

    @sensor.query(params[:device_id]).to_json
  end

  get '/metrics' do
    @device_id = params[:device_id]
    
    data = @sensor.query(@device_id)

    @up.set({ device_id: @device_id }, data['success'] ? 1 : 0)
    @device_live.set({ device_id: @device_id }, data['device_live'] ? 1 : 0)
    @temperature.set({ device_id: @device_id }, data['temp'])
    @heat_point.set({ device_id: @device_id}, data['heat_point'])
    @cool_point.set({ device_id: @device_id}, data['cool_point'])
    @status.set({ device_id: @device_id }, data['status'])
    @heating.set({ device_id: @device_id }, data['heating'])
    @cooling.set({ device_id: @device_id }, data['cooling'])
    @fan_status.set({ device_id: @device_id }, data['fan_status'] ? 1 : 0)
    @humidity.set({ device_id: @device_id }, data['humidity'])
    Prometheus::Client::Formats::Text.marshal(@registry)
  end

  run! if app_file == $PROGRAM_NAME
end
