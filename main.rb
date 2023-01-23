require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'nokogiri'
  gem 'pry'
  gem 'httparty'
  gem 'concurrent-ruby'
  gem 'sqlite3'
end

puts 'Gems installed and loaded!'

# Order of execution:
# 1. Get the number of books in the series.
# 2. Get the number of pages in the series.
# 3. Get the URL of a page in the series.
# 4. Scrape the HTML of all pages in the series. Return an array of Nokogiri objects.
# 5. Extract the book information from each page. Return an array of hashes.
# 6. Write the book information to a CSV file.

class Scraper
  require 'httparty'
  require 'csv'
  require 'pathname'
  require 'concurrent'
  require 'logger'
  require 'sqlite3'

  require_relative 'database_handler'

  BASE_URL = 'https://www.penguin.co.uk'
  SERIES = '/series/CLOTBO/penguin-clothbound-classics'
  BOOKS_PER_PAGE = 20

  def initialize
    # The logger should be first line of initialize
    @logger = Logger.new(File.new("#{File.dirname(__FILE__)}/logs/debug.log", 'w'))
    @books_count = books_count
    @page_count = (@books_count / BOOKS_PER_PAGE.to_f).ceil
    @pages_html = scrape_pages_html
    @books = []
  end

  # Make @books an attr_reader
  attr_reader :books

  def fetch_and_parse(url)
    @logger.info "Fetching #{url}"
    response = HTTParty.get(url)
    html = response.body
    Nokogiri::HTML(html)
  rescue Exception => e
    @logger.error e.message
  end

  def books_count
    html_doc = fetch_and_parse(get_page_url(99))
    books_count_xpath = '/html/body/div[1]/div/main/div/div[1]/div[1]'
    books_count_header = html_doc.xpath(books_count_xpath).text
    @books_count = books_count_header.split(' ')[0].to_i
  end

  def get_page_url(number)
    "#{BASE_URL}#{SERIES}?page=#{number}"
  end

  def scrape_pages_html
    promises = (1..@page_count).map do |page_no|
      Concurrent::Promise.execute { fetch_and_parse(get_page_url(page_no)) }
    end
    Concurrent::Promise.zip(*promises).value
  end

  def extract_from_details_page(url)
    html_doc = fetch_and_parse(url)
    {
      summary: html_doc.search('.Synopsis_synopsis__3JFsv').text.strip,
      author_information: html_doc.search('.Authors_author-info__21mvT').text.strip
    }
  end

  BOOK_CARD_WRAPPER = '.BookCard_wrapper__glKRr'
  BOOK_CARD_TITLE = '.BookCard_title__2wlQQ'
  BOOK_CARD_AUTHOR = '.BookCard_caption__3On-D span:nth-child(2)'

  def extract_book_information(html_doc, page)
    promises = html_doc.search(BOOK_CARD_WRAPPER).map.with_index do |book, index|
      relative_url = book.attribute('href').value
      full_url = "#{BASE_URL}#{relative_url}"
      Concurrent::Promise.execute { extract_from_details_page(full_url) }.then do |book_details|
        {
          page: page,
          index: index + 1,
          relative_url: relative_url,
          full_url: full_url,
          title: book.search(BOOK_CARD_TITLE).text.strip,
          author: book.search(BOOK_CARD_AUTHOR).text.strip,
          summary: book_details[:summary],
          author_information: book_details[:author_information]
        }
      end
    end
    Concurrent::Promise.zip(*promises).value
  end

  def extract_all_book_information
    @pages_html.map.with_index do |html_doc, page|
      @books.concat(extract_book_information(html_doc, page + 1))
    end
  end

  def write_to_csv(filename)
    headers = @books.first.keys
    file_path = Pathname.new(File.dirname(__FILE__)).join(filename)
    CSV.open(file_path, 'w', headers: headers, write_headers: true) do |csv|
      @books.each do |book|
        csv << book.values
      end
    end
  end
end

scraper = Scraper.new
scraper.extract_all_book_information
scraper.write_to_csv('books_data.csv')

db_handler = DatabaseHandler.new('books_data.db', scraper.books)
db_handler.write_to_db
