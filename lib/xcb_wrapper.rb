# High-level Ruby XCB Wrapper
# Provides Ruby-style object-oriented interface to XCB

require_relative 'xcb_complete'  # Low-level FFI bindings
require_relative 'xcb/wrapper'   # High-level wrapper classes

module XCB
  VERSION = "2.0.0"  # Wrapper version
  
  # Additional colormap management
  class Colormap
    attr_reader :connection, :screen, :colormap_id
    
    def initialize(connection, screen, visual = nil)
      @connection = connection
      @screen = screen
      @colormap_id = connection.generate_id
      @visual = visual || screen.root_visual
      
      XCB.xcb_create_colormap(@connection.connection, 0, @colormap_id, 
                              @screen.root_window, @visual)
      connection.send(:register_resource, self)
    end
    
    def alloc_color(red, green, blue)
      cookie = XCB.xcb_alloc_color(@connection.connection, @colormap_id, red, green, blue)
      reply = XCB.xcb_alloc_color_reply(@connection.connection, cookie, nil)
      
      return nil if reply.null?
      
      pixel = reply.read_uint32
      pixel
    ensure
      # Free reply memory in real implementation
    end
    
    def alloc_named_color(color_name)
      # Simplified - в реальной реализации нужно использовать xcb_alloc_named_color
      case color_name.to_s.downcase
      when 'red' then alloc_color(65535, 0, 0)
      when 'green' then alloc_color(0, 65535, 0)
      when 'blue' then alloc_color(0, 0, 65535)
      when 'white' then @screen.white_pixel
      when 'black' then @screen.black_pixel
      else @screen.black_pixel
      end
    end
    
    def cleanup
      XCB.xcb_free_colormap(@connection.connection, @colormap_id) rescue nil
    end
    
    def inspect
      "#<XCB::Colormap id=#{@colormap_id}>"
    end
  end
  
  # Pixmap support
  class Pixmap
    attr_reader :connection, :pixmap_id, :width, :height, :depth
    
    def initialize(connection, drawable, width, height, depth = nil)
      @connection = connection
      @width = width
      @height = height
      @depth = depth || connection.default_screen.depth
      @pixmap_id = connection.generate_id
      
      XCB.xcb_create_pixmap(@connection.connection, @depth, @pixmap_id, 
                           drawable, @width, @height)
      connection.send(:register_resource, self)
    end
    
    def create_graphics_context(options = {})
      GraphicsContext.new(@connection, self, options)
    end
    
    def cleanup
      XCB.xcb_free_pixmap(@connection.connection, @pixmap_id) rescue nil
    end
    
    def inspect
      "#<XCB::Pixmap id=#{@pixmap_id} #{@width}x#{@height}>"
    end
  end
end