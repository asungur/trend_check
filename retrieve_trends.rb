require 'json'
require 'uri'
require 'net/http'
require 'yaml'

class RetrieveTrends
  attr_reader :trends
  
  SECRET_TOKEN_YML = "../developer_data/token.yml"
  REQUEST_URI = "https://api.twitter.com/1.1/trends/place.json"

  def initialize(woeid)
    api_response = send_request(woeid)
    parsed_response = parse_json(api_response)
    @trends = if api_server_ok?(parsed_response)
                format_trends(parsed_response)
              else
                nil
              end
  end

  private

  def send_request(woeid)
    uri = URI(REQUEST_URI)
    params = { id: woeid }
    uri.query = URI.encode_www_form(params)

    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = load_bearer_token

    res = Net::HTTP.start(uri.hostname,
                           uri.port,
                           use_ssl: uri.scheme == 'https') do |http|
                            http.request(req)
                           end
  end

  def format_trends(json)
    parsed_arr = []
    json[0]["trends"].each do |hash|
      name = hash["name"]
      volume =  hash["tweet_volume"] == nil ? 0 : hash["tweet_volume"]
      parsed_arr.append([name.to_s, volume.to_s])
    end
    return parsed_arr
  end

  def api_server_ok?(json)
    !!json[0]
  end

  def parse_json(raw_response)
    JSON.parse(raw_response.body)
  end

  def load_bearer_token
    token_file = YAML.load_file(File.expand_path(SECRET_TOKEN_YML, __FILE__))
    token_file["token"]
  end
end
