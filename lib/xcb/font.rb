module XCB
  class Font
    attr_reader :connection, :font_id, :name
    
    def initialize(connection, font_name)
      @connection = connection
      @name = font_name
      @font_id = connection.generate_id
      
      load_font
      connection.send(:register_resource, self)
    end
    
    def query_info
      cookie = XCB.xcb_query_font(@connection.connection, @font_id)
      reply = XCB.xcb_query_font_reply(@connection.connection, cookie, nil)
      
      return nil if reply.null?
      
      # Извлекаем информацию из reply
      # Это упрощенная версия - в реальности нужно правильно парсить структуру
      info = {
        ascent: reply.read_int16,
        descent: reply.read_int16
      }
      
      info
    ensure
      # Освобождаем память reply
      # В реальной реализации нужно вызвать free(reply)
    end
    
    def height
      info = query_info
      info ? info[:ascent] + info[:descent] : 13  # fallback
    end
    
    def cleanup
      XCB.xcb_close_font(@connection.connection, @font_id) rescue nil
    end
    
    def inspect
      "#<XCB::Font name='#{@name}' id=#{@font_id}>"
    end
    
    # Class methods for common fonts
    def self.load(connection, font_name)
      new(connection, font_name)
    end
    
    def self.fixed(connection)
      new(connection, "fixed")
    end
    
    def self.system(connection, size = 13)
      new(connection, "#{size}x#{size + 2}")
    end
    
    private
    
    def load_font
      XCB.xcb_open_font(@connection.connection, @font_id, @name.length, @name)
      @connection.flush
    end
  end
end