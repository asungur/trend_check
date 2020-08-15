ENV["RACK_ENV"] = "test"

require "fileutils"

require "minitest/autorun"
require "rack/test"

require_relative "../trend_check"

class TrendCheckTest < Minitest::Test
  include Rack::Test::Methods

  LOCATIONS = [
                "United Kingdom",
                "Birmingham",
                "Blackpool",
                "Bournemouth",
                "Brighton",
                "Bristol",
                "Cardiff",
                "Coventry",
                "Derby",
                "Edinburgh",
                "Glasgow",
                "Hull",
                "Leeds",
                "Leicester",
                "Liverpool",
                "Manchester",
                "Middlesbrough",
                "Newcastle",
                "Nottingham",
                "Plymouth",
                "Portsmouth",
                "Preston",
                "Sheffield",
                "Stoke-on-Trent",
                "Swansea",
                "London",
                "Belfast"
              ].freeze



  
  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  def delete_username(username)
    path = File.expand_path("../users.yml", __FILE__)

    credentials = YAML.load_file(path).to_h

    credentials.delete(username)
    File.write(path, credentials.to_yaml)
  end

  def test_home
    get "/"
    assert_equal 302, last_response.status
    assert_includes last_response["Location"], "/uk"
  end

  def test_uk
    get "/uk"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "United Kingdom"
  end

  def test_locations_table_for_all_pages
    LOCATIONS.each_with_index do |loc, i|
      link = "/" + (i == 0 ? "uk" : loc.downcase)
      get link
      
      assert assert_equal 200, last_response.status
      assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
      LOCATIONS.each do |name|
        assert_includes last_response.body, name
      end
    end
  end

  def test_reload_trends_without_user_login
    get "/refresh-api"

    assert_equal 302, last_response.status
    assert_equal "You must be logged in to reload trends.", session[:message]
  end

  def test_sort_trends_by_id
    sort = "?sort=id"
    rev_sort = "?sort=id&reversed=true"

    LOCATIONS.each_with_index do |loc, i|
      link = "/" + (i == 0 ? "uk" : loc.downcase)

      get (link + sort)
      assert_equal 200, last_response.status
      assert_includes last_response.body, rev_sort

      get (link + rev_sort)
      assert_equal 200, last_response.status
      assert_includes last_response.body, sort
    end
  end

  def test_sort_trends_by_name
    sort = "?sort=name"
    rev_sort = "?sort=name&reversed=true"

    LOCATIONS.each_with_index do |loc, i|
      link = "/" + (i == 0 ? "uk" : loc.downcase)

      get (link + sort)
      assert_equal 200, last_response.status
      assert_includes last_response.body, rev_sort

      get (link + rev_sort)
      assert_equal 200, last_response.status
      assert_includes last_response.body, sort
    end
  end

  def test_sort_trends_by_volume
    sort = "?sort=volume"
    rev_sort = "?sort=volume&reversed=true"

    LOCATIONS.each_with_index do |loc, i|
      link = "/" + (i == 0 ? "uk" : loc.downcase)

      get (link + sort)
      assert_equal 200, last_response.status
      assert_includes last_response.body, rev_sort

      get (link + rev_sort)
      assert_equal 200, last_response.status
      assert_includes last_response.body, sort
    end
  end

  def test_login
    post "/signin", username: "admin", password: "secret"
    
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    get "/uk"
    assert_includes last_response.body, "admin"
  end

  def test_wrong_login
    post "/signin", username: "nonexistent", password: "secret"

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid credentials"

    post "/signin", username: "admin", password: "123123"

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_logout
    get "/signout", {}, {"rack session" => {username: "admin"}}

    assert_equal 302, last_response.status
    assert_nil session[:username]
    assert_equal "Log out successful.", session[:message]
  end

  def test_signup
    post "/signup", username: "tempUser", password1: "1234567", password2: "1234567"

    assert_equal 302, last_response.status
    assert_equal "You have successfully registered.", session[:message]
    delete_username("tempUser")
  end

  def test_invalid_signup_username
    post "/signup", username: "", password1: "1234567", password2: "1234567"
    invalid_username = 'Invalid username!'\
    ' Username must be at least 3 character long'\
    ' and should only contain word characters.'

    assert_equal 422, last_response.status
    assert_includes last_response.body, invalid_username

    post "/signup", username: "admin", password: "1234567", password2: "1234567"

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username is taken!"
  end

  def test_invalid_signup_password
    message_no_match = "Passwords do not match!"
    message_invalid = "Password must be at least 6 characters long and can not contain whitespace!"

    post "/signup", username: "tempUser", password1: "1234567", password2: "asdasda"

    assert_equal 422, last_response.status
    assert_includes last_response.body, message_no_match

    post "/signup", username: "tempUser", password1: "1223", password2: "1223"

    assert_equal 422, last_response.status
    assert_includes last_response.body, message_invalid

    post "/signup", username: "tempUser", password1: "12 \t5612", password2: "12 \t5612"

    assert_equal 422, last_response.status
    assert_includes last_response.body, message_invalid
  end

  def test_signin
    get "/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "username"
    assert_includes last_response.body, "password"
  end

  def test_signup
    get "/signup"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "username"
    assert_includes last_response.body, "password1"
    assert_includes last_response.body, "password2"
  end
end
