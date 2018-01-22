require 'selenium-webdriver'
require 'capybara'
require 'geocoder'

# Configurations
Capybara.register_driver :selenium do |app|  
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end
Capybara.javascript_driver = :chrome
Capybara.configure do |config|  
  config.default_max_wait_time = 10 # seconds
  config.default_driver = :selenium
end

class Listing
  attr_accessor :name, :street_address, :city_province_postal_code, :phone, :geocoder_result

  @@home = Geocoder.search('73 Bartlett Ave, Toronto ON').first
  @@work = Geocoder.search('161 Bay Street, Toronto ON').first

  def initialize(node)
    @name = get_field(node, '.listing-title')
    @street_address = get_field(node, '.wpbdp-field-street_address')
    @city_province_postal_code = get_field(node, '.wpbdp-field-city_province_postal_code')
    @phone = get_field(node, '.wpbdp-field-telephone')
    @geocoder_result = Geocoder.search("#{@street_address} #{@city_province_postal_code}").first
  end

  def get_field(node, field_name)
    node.find_all(field_name).first&.text
  end

  def distance_from_home
    Geocoder::Calculations.distance_between(@@home.coordinates, @geocoder_result.coordinates)
  end

  def distance_from_work
    Geocoder::Calculations.distance_between(@@work.coordinates, @geocoder_result.coordinates)
  end
end

def listings_for_page(i)
  browser = Capybara.current_session
  url = "http://www.en.psychoanalysis.ca/find-a-psychoanalyst/wpbdp_category/toronto-psychoanalytic-society/page/#{i}/?lang=en"
  browser.visit(url)
  browser.find_all('.wpbdp-listing').map { |node| Listing.new(node) }
end

all_listings = (1..5).flat_map { |i| listings_for_page(i) }.reject { |l| l.geocoder_result.nil? }
