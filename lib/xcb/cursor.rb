module XCB
  class Cursor
    attr_reader :connection, :cursor_id
    
    STANDARD_CURSORS = {
      arrow: 2,
      crosshair: 34, 
      hand: 58,
      watch: 150,
      text: 152
    }.freeze
    
    def initialize(connection, cursor_type = :arrow)
      @connection = connection
      @cursor_id = connection.generate_id
      
      create_cursor(cursor_type)
      connection.send(:register_resource, self)
    end
    
    def cleanup
      XCB.xcb_free_cursor(@connection.connection, @cursor_id) rescue nil
    end
    
    def inspect
      "#<XCB::Cursor id=#{@cursor_id}>"
    end
    
    # Class methods for creating different cursors
    def self.arrow(connection)
      new(connection, :arrow)
    end
    
    def self.crosshair(connection)
      new(connection, :crosshair)
    end
    
    def self.hand(connection)
      new(connection, :hand)
    end
    
    def self.watch(connection)
      new(connection, :watch)
    end
    
    def self.text(connection)
      new(connection, :text)
    end
    
    # Create cursor from pixmap (advanced usage)
    def self.from_pixmap(connection, pixmap, mask, foreground_rgb, background_rgb, hotspot_x, hotspot_y)
      cursor = allocate
      cursor.send(:initialize_from_pixmap, connection, pixmap, mask, foreground_rgb, background_rgb, hotspot_x, hotspot_y)
      cursor
    end
    
    private
    
    def create_cursor(cursor_type)
      if cursor_type.is_a?(Symbol) && STANDARD_CURSORS.key?(cursor_type)
        create_standard_cursor(cursor_type)
      elsif cursor_type.is_a?(Integer)
        create_glyph_cursor(cursor_type)
      else
        create_standard_cursor(:arrow)
      end
    end
    
    def create_standard_cursor(cursor_type)
      glyph = STANDARD_CURSORS[cursor_type]
      create_glyph_cursor(glyph)
    end
    
    def create_glyph_cursor(glyph)
      # Загружаем шрифт курсоров
      cursor_font = @connection.generate_id
      XCB.xcb_open_font(@connection.connection, cursor_font, 6, "cursor")
      
      # Создаем курсор из глифа
      XCB.xcb_create_glyph_cursor(@connection.connection, @cursor_id, 
                                  cursor_font, cursor_font,
                                  glyph, glyph,
                                  0, 0, 0,           # foreground (black)
                                  65535, 65535, 65535) # background (white)
      
      # Закрываем временный шрифт
      XCB.xcb_close_font(@connection.connection, cursor_font)
      @connection.flush
    end
    
    def initialize_from_pixmap(connection, pixmap, mask, foreground_rgb, background_rgb, hotspot_x, hotspot_y)
      @connection = connection
      @cursor_id = connection.generate_id
      
      fg_r, fg_g, fg_b = foreground_rgb
      bg_r, bg_g, bg_b = background_rgb
      
      XCB.xcb_create_cursor(@connection.connection, @cursor_id, pixmap, mask,
                            fg_r, fg_g, fg_b, bg_r, bg_g, bg_b, hotspot_x, hotspot_y)
      @connection.flush
      
      connection.send(:register_resource, self)
    end
  end
end