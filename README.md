![Trend Check demo](/public/trend_check_demo.gif)

## Description

**Trend Check** is a website that I've built while playing with TwitterAPI. It is written in Ruby and Sinatra, uses ERB view templates and PostgreSQL database. It also benefits from [Google Charts](https://developers.google.com/chart) (GeoCharts to be more specific) for displaying locations and top trends on a UK map.

Website displays top **Twitter trend**s for United Kingdom and 26 cities that exist in Yahoo's [WOEID](https://en.wikipedia.org/wiki/WOEID) database. In the main UK page, top trends in the UK will be listed on the table. The map displays individual cities, their total trend volumes (as much as provided by TwitterAPI) and the top trend for each city. Pages of individual cities list top trends for that location with an identifier on the UK map.

Trends can be reloaded from the TwitterAPI. For now this functionality is only open to registered users since TwitterAPI has a rate limit for this operation. Registration uses [BCrypt](https://github.com/codahale/bcrypt-ruby) for hashing passwords. However, this website is not using https, be mindful while choosing your password.




## Architecture

Application consists of 4 ruby classes:

- trend_check (main app)
- database_persistence
- retrieve_trends
- location

The `trend_check` is the main Sinatra application that interfaces between user and the server. It handles the incoming requests and passes it to the database. It receives information from the server and passes it to the views. It also handles user log-in/log-out processes.

The `database_persistence` is responsible for reading/writing the database. It uses [PG gem](https://github.com/ged/ruby-pg) to interface to the PostgreSQL RDBMS. Incoming method calls from the main application is processed here. If this involves retrieving the new trends from TwitterAPI, this request is forwarded to `retrieve_trends` and returned `json` data will be written to the database. If the incoming method calls require interaction with the database, these will be executed as SQL queries and the results will be processed before it is sent to the `trend_check` .

The `retrieve_trends` issues **[GET trends/place](https://developer.twitter.com/en/docs/twitter-api/v1/trends/trends-for-location/api-reference/get-trends-place)** requests to TwitterAPI. This operation is being executed following method calls from `database_persistence`. Provider's response will be sanitized here and forwarded to back to `database_persistence` in `json` format.

`location` provides sort links for the main application.
 <br/> 
 <br/> 
![Architecture](/public/Architecture.png)
 <br/> 
 </br> 
## Setup

 After you clone the repository, install gems and run the application with `bundle exec`:

```ruby
git clone https://github.com/asungur/trend_check
bundle install
bundle exec ruby trend_check.rb
```

This will run the app on [`http://localhost:4567/`](http://localhost:4567/) . This project uses ruby version  2.6.5. Use the **Gemfile** If you want to change it. (This might raise dependency issues)

```ruby
source "https://rubygems.org"

ruby "2.6.5"
.
.
.
```

Re-run `bundle install` before you run the app.

For **GoogleCharts** [here](https://github.com/asungur/trend_check/blob/master/views/layout.erb)**,** you need to register [Google Charts](https://developers.google.com/chart) and create an API key. Replace `mapsApiKey` in `layout.erb`

```ruby
.
.
google.charts.load('current', {
        'packages': ['geochart'],
        'mapsApiKey' : 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
      });
      google.charts.setOnLoadCallback(drawMarkersMap);
.
.
```

For accessing **TwitterAPI** provider, you need to create [a developer account](https://developer.twitter.com/en/docs) and get an API key. Use your key to [create a Bearer token](https://developer.twitter.com/en/docs/authentication/oauth-2-0/bearer-tokens). Lastly, update the link to your token in `retrieve_trends.rb`:

```ruby
.
.
class RetrieveTrends
  attr_reader :trends
  SECRET_TOKEN_YML = "../developer_data/token.yml"
  REQUEST_URI = "https://api.twitter.com/1.1/trends/place.json"
.
.
```


## Tests

I've used [minitest](https://github.com/seattlerb/minitest) library with `rack/test` helper methods. Tests mainly focus on retrieve the relevant pages, user log-in/log-out functionalities. Run the tests from the project directory:

```ruby
bundle exec ruby test/trend_check_test.rb
```

## Further Development

I've focused on the back-end primarily. There are a few improvements can be done on the front-end that potentially can make the app run faster. Vanilla JS or React can be used for this improvement.

There are couple of known issues that I am planning to look at:

- ✅ Speed of the database. Identify and optimize N+1 queries.
- 🕑 [Twitter](https://github.com/twitter) published TwitterAPI v2. Have a look at it for potential improvements.
- 🕑 User registration is open-to-public for now. Might close it depending on server load.
- 🕑 Google GeoChart is quite slow. Find an alternative/improve.

## Contact

You can report any issues/requests [here](https://github.com/asungur/trend_check/issues). Always open to a conversation. DM me on [Twitter](https://twitter.com/asungur_) or [write me an e-mail](mailto:sunguralican@gmail.com)
