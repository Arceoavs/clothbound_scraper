require 'bundler/inline'

gemfile do
	source 'https://rubygems.org'
	gem 'nokogiri'
	gem 'pry'
	gem 'httparty'
end

puts 'Gems installed and loaded!'

require "httparty"
require "csv"
require 'pathname'

# Order of execution:
# 1. Get the number of books in the series.
# 2. Get the number of pages in the series.
# 3. Get the URL of a page in the series.
# 4. Scrape the HTML of all pages in the series. Return an array of Nokogiri objects.

BASE_URL = "https://www.penguin.co.uk/series/CLOTBO/penguin-clothbound-classics?page="

def fetch_and_parse(url)
  begin
    response = HTTParty.get(url)
    html = response.body
    Nokogiri::HTML(html)
  rescue Exception => e
    puts e.message
  end
end

def books_count 
	html_doc = fetch_and_parse(get_page_url(99))
	books_count_xpath = "/html/body/div[1]/div/main/div/div[1]/div[1]"
	books_count_header = html_doc.xpath(books_count_xpath).text
	books_count = books_count_header.split(" ")[0].to_i
	return books_count
end

# Get the number of pages in the series. This is derived from the number of books in the series, and the number of books per page.
def page_count
	books_per_page = 20
	pages_rounded_up = ( books_count / books_per_page.to_f).ceil
	return pages_rounded_up
end

# Get the URL of a page in the series.
def get_page_url(number) 
	"#{BASE_URL}#{number}"
end

# Scrape the HTML of all pages in the series. Return an array of HTML strings.
def scrape_pages_html
    (1..page_count).map { |page_no| fetch_and_parse(get_page_url(page_no)) }
end

BOOK_CARD_WRAPPER = '.BookCard_wrapper__glKRr'
BOOK_CARD_TITLE = '.BookCard_caption__3On-D span:first-child'
BOOK_CARD_AUTHOR = '.BookCard_caption__3On-D span:nth-child(2)'

def extract_book_information(html_doc, page)
    begin
        books = html_doc.search(BOOK_CARD_WRAPPER)
        books.map.with_index do |book, index|
            {
                page: page,
                index: index + 1,
                link: book.attribute('href').value,
                title: book.search(BOOK_CARD_TITLE).text.strip,
                author: book.search(BOOK_CARD_AUTHOR).text.strip
            }
        end
    rescue Exception => e
        puts e.message
    end
end

def extract_all_book_information
    scrape_pages_html.map.with_index do |html_doc, index|
        extract_book_information(html_doc, index + 1)
    end.flatten.compact
end

require 'csv'

require 'csv'
require 'pathname'

def write_books_to_csv(books)
  headers = books.first.keys
  file_path = Pathname.new(File.dirname(__FILE__)).join("books_data.csv")
  CSV.open(file_path, "w", headers: headers, write_headers: true) do |csv|
    books.each do |book|
      csv << book.values
    end
  end
end


write_books_to_csv(extract_all_book_information())
