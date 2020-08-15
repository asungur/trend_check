class Location
  attr_reader :name
  SORTABLE_DATA = { 
    "#" => "id",
    "Trend" => "name",
    "Tweet Volume" => "volume",
  }

  def initialize(name)
    @name = name
  end

  def sort_links(reversed)
    result = {}
    SORTABLE_DATA.each_with_index do |(name, link)|
      rev = reversed ? "" : "&reversed=true"

      html = "<a class=\"text-secondary\" href=\"/#{@name}" \
             "?sort=#{link}#{rev}\">#{name}</a>"
      result[name] = html
    end
    result
  end

end