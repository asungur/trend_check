require "json"
require "pg"

require_relative "retrieve_trends"

class DBPersistence
  attr_reader :locations

  def initialize
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "trends")
          end
    @locations = get_locations
  end

  def delete_all
    sql_1 = <<~SQL 
      DELETE FROM trends
    SQL

    sql_2 = <<~SQL 
      ALTER SEQUENCE trends_id_seq RESTART WITH 1
    SQL

    query(sql_1)
    query(sql_2)
  end

  def reload_all
    @locations.each { |loc| load_trends(loc) }
  end

  def disconnect
    @db.close
  end

  def list_trends(location, sort_by, reversed)
    sql = <<~SQL
      SELECT t.id, t.name, t.volume 
      FROM trends AS t
      INNER JOIN locations AS l
      ON (t.location_id = l.id)
      WHERE (l.name = $1)
      ORDER BY #{sort_by}
    SQL

    sql = add_reverse(sql, reversed)

    result = query(sql, location)

    newRes = result.map do |tuple|
               tuple_to_list_hash_trend(tuple)
             end
    
    alter_ids(newRes)
  end

  def town_volumes()

    sql_volume = <<~SQL
      SELECT l.name,
             SUM(t.volume) AS total_volume
      FROM trends AS t
      INNER JOIN locations AS l
      ON (t.location_id = l.id)
      WHERE (l.id != 27)
      GROUP BY l.id
      ORDER BY l.id ASC;
    SQL

    town_volumes = query(sql_volume)

    tuple_to_list_hash_volumes(town_volumes)
  end

  def town_top_trends()
    sql_top_trends = <<~SQL
      SELECT l.name AS town,
             y.name AS trend,
             y.volume
      FROM (SELECT t.name,
                   t.location_id,
                   t.volume
            FROM (SELECT location_id, 
                         MAX(volume) as max_volume
                  FROM trends
                  GROUP BY location_id ) AS m
            INNER JOIN trends AS t
            ON  (t.location_id = m.location_id)
            AND (t.volume = m.max_volume)
            WHERE (t.location_id != 27) ) AS y
      INNER JOIN locations as l
      ON (y.location_id = l.id);
    SQL

    trend_result = query(sql_top_trends)

    tuple_to_list_hash_top_trends(trend_result)
  end

  private

  def get_locations
    sql = <<~SQL
      SELECT name FROM locations
      ORDER BY id;
    SQL
    result = query(sql)
    result.values.map { |arr| arr[0] }
  end

  def query(sql, *params)
    # puts "\n"
    # puts sql
    # puts "\n"
    # puts params
    # puts "\n" + "----------------------" + "\n"
    @db.exec_params(sql, params)
  end

  def clear_trends(id)
    sql = <<~SQL
      DELETE FROM trends
      WHERE (location_id = $1);
    SQL
    query(sql, id)
  end

  def load_trends(location)
    loc_info = retrieve_loc_info(location)
    loc_woeid = loc_info["woeid"].to_i
    loc_id = loc_info["id"].to_i

    trends = retrieve_loc_trends(loc_woeid)

    return nil if trends == nil

    clear_trends(loc_id)

    sql = <<~SQL
      INSERT INTO trends (name, volume, location_id)
      VALUES ($1, $2, $3);
    SQL

    trends.each do |trend|
      values = [ trend[0], trend[1], loc_id ]
      query(sql, *values)
    end
  end

  def retrieve_loc_trends(woeid)
    api_location = RetrieveTrends.new(woeid)
    api_location.trends
  end

  def retrieve_loc_info(location)
    sql = <<~SQL
      SELECT id,woeid FROM locations
      WHERE name = ($1);
    SQL
    result = query(sql, location)
    result.first
  end

  def load_locations
    sql = <<~SQL
      INSERT INTO locations (name, type, woeid )
      VALUES ($1, $2, $3)
    SQL

    loc_json = File.read('data/gb_woeid.json')
    loc_array = JSON.parse(loc_json)

    loc_array.each do |loc|
      values = [ loc["name"], loc["placeType"]["name"], loc["woeid"] ]
      query(sql, *values)
    end
  end

  def tuple_to_list_hash_volumes(result)
    result.map do |tuple|
      {
        name: tuple["name"],
        total_volume: tuple["total_volume"].to_i
      }
    end
  end

  def tuple_to_list_hash_top_trends(result)
    result.map do |tuple|
      {
        name: tuple["town"],
        trend: tuple["trend"],
        trend_volume: tuple["volume"].to_i
      }
    end
  end

  def tuple_to_list_hash_trend(tuple)
    { 
      id: tuple["id"].to_i,
      name: tuple["name"],
      volume: tuple["volume"].to_i
    }
  end

  def add_reverse(sql, reversed = false)
    asc = <<~SQL
      ASC;
    SQL

    desc = <<~SQL
      DESC;
    SQL

    sql += reversed ? desc : asc
  end

  def alter_ids(collection)
    min_id = collection.map { |trend| trend[:id].to_i }.min

    collection.map do |trend|
      { 
        id: (trend[:id] - min_id),
        name: trend[:name],
        volume: trend[:volume],
      }
    end
  end
end