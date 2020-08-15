require "yaml"
require "sinatra"
require "tilt/erubis"
require "bcrypt"

require_relative "database_persistence"
require_relative "location"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "retrieve_trends.rb"
  also_reload "database_persistence.rb"
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def add_user_credentials(username, password)
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end

  bcrypt_password = BCrypt::Password.create(password).to_s
  credentials = YAML.load_file(credentials_path).to_h

  credentials[username] = bcrypt_password
  File.write(credentials_path, credentials.to_yaml)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to reload the trends"
    redirect "/uk"
  end
end

def location_links()
  locations(:all).map do |name|
    {
      link: (name == "United Kingdom" ? "uk" : name.downcase),
      name: name
    }
  end
end

def locations(type = :town)
  arr_locations = []
  uk = "United Kingdom"
  @storage.locations.each do |location| 
    arr_locations << location unless location == uk
  end
  case type
  when :country
    arr_locations = [uk]
  when :all
    arr_locations.insert(0, uk)
  end
  arr_locations
end

def name_from_link(link)
  town_name = nil

  @loc_navigators.each do |set|
    if set[:link] == link
      town_name = set[:name]
    end
  end

  return town_name
end

def invalid_username?(username)
  !(username == username.gsub(/\W/, "") && username.length >= 3)
end

def invalid_password?(password)
  !(password == password.gsub(/\s/, "") && password.length >= 6)
end

def invalid_signup(username, pass1, pass2)
  message = ""
  usernames = load_user_credentials.keys

  if invalid_username?(username)
    message = 'Invalid username!'\
    ' Username must be at least 3 character long'\
    ' and should only contain word characters.'
  elsif usernames.include?(username)
    message = "Username is taken!"
  elsif pass1 != pass2
    message = "Passwords do not match!"
  elsif invalid_password?(pass1)
    message = "Password must be at least 6 characters long and can not contain whitespace!"
  end
  message
end

def towns_data()
  overview = @storage.town_top_trends
  names = overview.map { |hash| hash[:name] }


  @storage.town_volumes.each_with_index do |value, i|
    idx = names.index(value[:name])

    overview[idx][:total_volume] = value[:total_volume]
  end

  overview
end

before do
  @storage = DBPersistence.new

  @loc_navigators = location_links

  @towns_overview = towns_data
end

after do
  @storage.disconnect
end

helpers do
  def chop_hashtag(string)
    string[0] == "#" ? string[1..-1] : string
  end

  def format_number(num)
    flipped_str = num.to_s.split('').reverse
    flipped_formatted = []
    flipped_str.each_with_index do |num, i|
      flipped_formatted << num
      if (i + 1) % 3 == 0 && (i + 1) < flipped_str.length
        flipped_formatted << ','
      end
    end
    flipped_formatted.reverse.join('')
  end
end

get "/" do
  redirect "/uk"
end

get "/uk" do
  reversed = !!params[:reversed]
  sort = !!params[:sort] ? params[:sort] : "id"

  uk = Location.new("uk")
  @table_sorts = uk.sort_links(reversed)

  @uk_trends = @storage.list_trends("United Kingdom", sort, reversed)

  @uk_towns_volume = @towns_overview

  erb :main
end

get "/refresh-api" do
  if !!session[:username]
    @storage.reload_all
  else
    session[:message] = "You must be logged in to reload trends."
    status 422
  end
  redirect "/uk"
end

get "/signin" do
  erb :signin 
end

get "/signup" do
  erb :signup
end

get "/signout" do
  session.delete(:username)

  session[:message] = "Log out successful."

  redirect "/uk"
end

post "/signin" do
  username = params[:username]
  password = params[:password]

  if valid_credentials?(username, password)
    session[:username] = params[:username]
    session[:message] = "Welcome!"
    redirect "/uk"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post "/signup" do
  username = params[:username]
  password1 = params[:password1]
  password2 = params[:password2]

  signup_error = invalid_signup(username, password1, password2)

  if signup_error != ""
    session[:message] = signup_error

    status 422
    erb :signup
  else
    add_user_credentials(username, password1)
    session[:message] = "You have successfully registered."

    redirect "/uk"
  end
end

get "/:town" do
  reversed = !!params[:reversed]
  sort = !!params[:sort] ? params[:sort] : "id"

  town_name = name_from_link(params[:town])

  
  town = Location.new(params[:town])
  @table_sorts = town.sort_links(reversed)

  @town_trends = @storage.list_trends(town_name, sort, reversed)

  town_index = @towns_overview.map{ |hash| hash[:name] }.index(town_name)

  @town_data = @towns_overview[town_index]

  erb :town
end