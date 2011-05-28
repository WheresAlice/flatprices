require 'hpricot'
require 'open-uri'
require 'sinatra'
require 'haml'

set :haml, :format => :html5

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
    #prices = []
    #doc = open("http://www.gumtree.com/flats-and-houses-for-rent-offered/#{name.downcase}") { |f| Hpricot(f) }
    #doc.search("//div[@class='price']").each do |price|
    #  prices.push( price.inner_text[/[0-9]+\.?[0-9]+/].to_i )
    #end
    #prices.mean
    rand(400)
  end
end

get '/' do
  haml :index, :locals => { :Cities => {:Bradford => "&pound;#{City.new('Bradford').flatprice}", :Leeds => "&pound#{City.new('Leeds').flatprice}", :Manchester => "&pound'#{City.new('Manchester').flatprice}", :Newcastle => "&pound;#{City.new('Newcastle').flatprice}"}}
end
