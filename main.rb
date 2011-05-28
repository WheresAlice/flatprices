require 'hpricot'
require 'open-uri'
require 'sinatra'
require 'haml'

set :haml, :format => :html5

configure do
  require 'redis'
  uri = URI.parse(ENV["REDISTOGO_URL"])
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end
  
  def mean
    sum / size
  end
end

# Methods to return data about a given city
class City
  attr_accessor :name
  
  # Takes the city name, which is treated as case sensitive by Redis
  def initialize(name)
    @name = name
  end
  
  def to_s
    name
  end
  
  # Returns an html output of the average flat price per week, as taken from Gumtree
  def flatprice
    ttl = REDIS.ttl(name)
    if (ttl < 0)
      prices = []
      doc = open("http://www.gumtree.com/flats-and-houses-for-rent-offered/#{name.downcase}") { |file| Hpricot(file) }
      doc.search("//div[@class='price']").each do |price|
        prices.push( price.inner_text[/[0-9]+\.?[0-9]+/].to_i )
      end
      REDIS.set name, prices.mean
      REDIS.expire name, 3600
      @prices = prices.mean
    else
      @prices = REDIS.get(name)
    end
    "&pound;#{sprintf("%.2f", @prices)}"
  end
end

# Main page
get '/' do
  haml :index, :locals => { :Cities => {
    :Bradford =>   City.new('Bradford').flatprice,
    :Hull =>       City.new('Hull').flatprice,
    :Leeds =>      City.new('Leeds').flatprice,
    :Manchester => City.new('Manchester').flatprice,
    :Newcastle =>  City.new('Newcastle').flatprice,
    :Sheffield =>  City.new('Sheffield').flatprice,
    :York =>       City.new('York').flatprice
  },
  :ttl => REDIS.ttl('Bradford')
  }
end

# Ping/Pong to provide a cheap way of detecting if the app is up
get '/ping' do
  'pong'
end
