# Penguin Clothbound Classics Scraper

This code scrapes book information from the Penguin Clothbound Classics series on the Penguin website and writes it to a CSV file. It utilizes the gems nokogiri, pry, httparty, and concurrent-ruby.

## How it works

1. The script first gets the number of books in the series and calculates the number of pages in the series.
2. It then scrapes the HTML of all pages in the series, returning an array of Nokogiri objects.
3. The script then extracts the book information from each page and returns an array of hashes.
4. The book information is then written to a CSV file.

## Usage

The script can be run using the provided `docker-compose.yaml` file in the repository.
Run `docker compose up` in the root directory to start the scraper.
Alternatively, you can run the script locally by running `ruby main.rb` in the root directory.
The script will create a `books.csv` file in the root directory with the extracted book information.
