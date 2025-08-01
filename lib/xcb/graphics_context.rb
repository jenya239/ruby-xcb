module XCB
  class GraphicsContext
    attr_reader :connection, :window, :gc_id
    
    DEFAULT_OPTIONS = {
      foreground: :black,
      background: :white,
      font: nil
    }.freeze
    
    def initialize(connection, window, options = {})
      @connection = connection
      @window = window
      @options = DEFAULT_OPTIONS.merge(options)
      @gc_id = connection.generate_id
      
      create_graphics_context
    end
    
    # Drawing operations
    def draw_point(x, y)
      point = XCB::Point.new
      point[:x] = x
      point[:y] = y
      
      XCB.xcb_poly_point(@connection.connection, 0, @window.window_id, @gc_id, 1, point)
      @connection.flush
      self
    end
    
    def draw_line(x1, y1, x2, y2)
      points = FFI::MemoryPointer.new(XCB::Point, 2)
      
      point1 = XCB::Point.new(points[0])
      point1[:x] = x1
      point1[:y] = y1
      
      point2 = XCB::Point.new(points[1])
      point2[:x] = x2
      point2[:y] = y2
      
      XCB.xcb_poly_line(@connection.connection, XCB::XCB_COORD_MODE_ORIGIN, 
                        @window.window_id, @gc_id, 2, points)
      @connection.flush
      self
    end
    
    def draw_rectangle(x, y, width, height, filled: false)
      rect = XCB::Rectangle.new
      rect[:x] = x
      rect[:y] = y
      rect[:width] = width
      rect[:height] = height
      
      if filled
        XCB.xcb_poly_fill_rectangle(@connection.connection, @window.window_id, @gc_id, 1, rect)
      else
        XCB.xcb_poly_rectangle(@connection.connection, @window.window_id, @gc_id, 1, rect)
      end
      
      @connection.flush
      self
    end
    
    def fill_rectangle(x, y, width, height)
      draw_rectangle(x, y, width, height, filled: true)
    end
    
    def draw_text(x, y, text)
      raise XCBError, "No font set for graphics context" unless @font
      
      XCB.xcb_image_text_8(@connection.connection, text.length, @window.window_id, 
                           @gc_id, x, y, text)
      @connection.flush
      self
    end
    
    # Configuration
    def set_foreground(color)
      pixel = resolve_color(color)
      change_gc(XCB::XCB_GC_FOREGROUND, pixel)
      self
    end
    
    def set_background(color)
      pixel = resolve_color(color)
      change_gc(XCB::XCB_GC_BACKGROUND, pixel)
      self
    end
    
    def set_font(font)
      @font = font
      font_id = font.respond_to?(:font_id) ? font.font_id : font
      change_gc(XCB::XCB_GC_FONT, font_id)
      self
    end
    
    def cleanup
      XCB.xcb_free_gc(@connection.connection, @gc_id) rescue nil
    end
    
    def inspect
      "#<XCB::GraphicsContext id=#{@gc_id}>"
    end
    
    private
    
    def create_graphics_context
      mask = 0
      values = []
      
      # Foreground
      if @options[:foreground]
        mask |= XCB::XCB_GC_FOREGROUND
        values << resolve_color(@options[:foreground])
      end
      
      # Background
      if @options[:background]
        mask |= XCB::XCB_GC_BACKGROUND
        values << resolve_color(@options[:background])
      end
      
      # Font
      if @options[:font]
        @font = @options[:font]
        mask |= XCB::XCB_GC_FONT
        font_id = @font.respond_to?(:font_id) ? @font.font_id : @font
        values << font_id
      end
      
      # Create values array
      if values.any?
        values_ptr = FFI::MemoryPointer.new(:uint32, values.size)
        values.each_with_index { |val, i| values_ptr[i].write_uint32(val) }
      else
        values_ptr = nil
        mask = 0
      end
      
      XCB.xcb_create_gc(@connection.connection, @gc_id, @window.window_id, mask, values_ptr)
    end
    
    def change_gc(mask, value)
      values_ptr = FFI::MemoryPointer.new(:uint32, 1)
      values_ptr.write_uint32(value)
      
      XCB.xcb_change_gc(@connection.connection, @gc_id, mask, values_ptr)
      @connection.flush
    end
    
    def resolve_color(color)
      case color
      when :white then @window.screen.white_pixel
      when :black then @window.screen.black_pixel
      when :red then 0xFF0000
      when :green then 0x00FF00
      when :blue then 0x0000FF
      when Integer then color
      else @window.screen.black_pixel
      end
    end
  end
end