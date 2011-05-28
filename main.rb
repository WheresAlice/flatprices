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

class City
  attr_accessor :name
  
  def initialize(name)
    @name = name
  end
  
  def to_s
    name
  end
  
  def flatprice
    ttl = REDIS.ttl(name.downcase)
    if (ttl < 0)
      prices = []
      doc = open("http://www.gumtree.com/flats-and-houses-for-rent-offered/#{name.downcase}") { |f| Hpricot(f) }
      doc.search("//div[@class='price']").each do |price|
        prices.push( price.inner_text[/[0-9]+\.?[0-9]+/].to_i )
      end
      REDIS.set name.downcase, prices.mean
      REDIS.expire name.downcase, 600
      @prices = prices.mean
    else
      @prices = REDIS.get(name.downcase)
    end
    @prices
  end
end

get '/' do
  haml :index, :locals => { :Cities => {
    :Bradford => "&pound;#{sprintf("%.2f", City.new('Bradford').flatprice)}",
    :Leeds => "&pound#{sprintf("%.2f", City.new('Leeds').flatprice)}",
    :Manchester => "&pound#{sprintf("%.2f", City.new('Manchester').flatprice)}",
    :Newcastle => "&pound;#{sprintf("%.2f", City.new('Newcastle').flatprice)}"
  }, :ttl => REDIS.ttl('bradford')}
end

get '/ping' do
  'pong'
end
