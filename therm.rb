require 'rubygems'
require 'active_support/all'
require 'mechanize'
require 'json'

class TempSensor
  def initialize(user, pass)
    @user = user
    @pass = pass
    @responses = {}

    @agent = Mechanize.new
    @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def query(device_id)
    data = JSON.parse(response(device_id).body)

    retval = {}
    retval['success'] = data['success']
    retval['device_live'] = data['deviceLive']
    retval['temp'] = data['latestData']['uiData']['DispTemperature']
    retval['heat_point'] = data['latestData']['uiData']['HeatSetpoint']
    retval['cool_point'] = data['latestData']['uiData']['CoolSetpoint']
    retval['device_id'] = data['latestData']['uiData']['DeviceID']
    retval['status'] = data['latestData']['uiData']['EquipmentOutputStatus']
    retval['fan_status'] = data['latestData']['fanData']['fanIsRunning']
    retval['heating'] = (data['latestData']['uiData']['EquipmentOutputStatus'] == 1) ? 1 : 0
    retval['cooling'] = (data['latestData']['uiData']['EquipmentOutputStatus'] == 2) ? 1 : 0

    retval
  end

  private

    def setup
      @agent.get('https://mytotalconnectcomfort.com/portal')

      @agent.post('https://mytotalconnectcomfort.com/portal',
                'timeOffset' => '240',
                'UserName' => @user,
                'Password' => @pass,
                'RememberMe' => 'false')
    end

    def response(device_id)

      if @responses[device_id] && @responses[device_id][:time] > 5.minutes.ago
        puts "Returning cached value it has been less than 5 minutes for #{device_id}"
        return @responses[device_id][:val]
      end

      puts 'Refreshing data for ' + device_id

      setup

      @responses[device_id] = {
        time: Time.now,
        val: @agent.get(
          "https://mytotalconnectcomfort.com/portal/Device/CheckDataSession/#{device_id}?_=#{Time.now.to_i * 1000}",
          [],
          "https://mytotalconnectcomfort.com/portal/Device/Control/#{device_id}",
          'X-Requested-With' => 'XMLHttpRequest'
        )
      }

      return @responses[device_id][:val]
    end
end
