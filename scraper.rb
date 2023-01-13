require 'net/http'

class Scraper
    def initialize
        @base_url = "https://www.penguin.co.uk"
    end

    def get_books_count
        url = "#{@base_url}/series/CLOTBO/penguin-clothbound-classics?page=99"
        response = Net::HTTP.get_response(URI(url))
        html_doc = Nokogiri::HTML(response.body)
        books_count_xpath = "/html/body/div[1]/div/main/div/div[1]/div[1]"
        books_count_header = html_doc.xpath(books_count_xpath).text
        books_count = books_count_header.split(" ")[0].to_i
        books_count
    rescue Timeout::Error, SocketError => e
        puts "Error: #{e.message}"
    end
end

