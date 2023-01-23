class DatabaseHandler
  def initialize(db_filename, books)
    @logger = Logger.new(File.new("#{File.dirname(__FILE__)}/logs/db.log", 'w'))
    @db_path = File.join(File.dirname(__FILE__), db_filename)
    @books = books
  end

  def write_to_db
    delete_db_if_exists
    db = open_db_connection
    create_books_table(db)
    check_books_array_empty
    insert_books_into_table(db)
    close_db_connection(db)
  end

  private

  def delete_db_if_exists
    return unless File.exist?(@db_path)

    File.delete(@db_path)
  end

  def open_db_connection
    SQLite3::Database.open @db_path
  rescue SQLite3::Exception => e
    @logger.error e.message
    raise "Error opening database: #{e.message}"
  end

  def create_books_table(db)
    db.execute "CREATE TABLE IF NOT EXISTS books (
                      page INTEGER,
                      book_index INTEGER,
                      relative_url TEXT,
                      full_url TEXT,
                      title TEXT,
                      author TEXT,
                      summary TEXT,
                      author_information TEXT
                    )"
  end

  def check_books_array_empty
    return unless @books.empty?

    @logger.error e.message
    raise 'Error writing to database: The books array is empty.'
  end

  def insert_books_into_table(db)
    db.transaction do |db|
      statement = db.prepare 'INSERT INTO books (page, book_index, relative_url, full_url, title, author, summary, author_information) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
      @books.each do |book|
        statement.execute book[:page], book[:index], book[:relative_url], book[:full_url], book[:title],
                          book[:author], book[:summary], book[:author_information]
      end
      statement.close
    end
  end

  def close_db_connection(db)
    db.close
  end
end
