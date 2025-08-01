module XCB
  class ScreenWrapper
    attr_reader :connection, :screen_data
    
    def initialize(connection, screen_ptr)
      @connection = connection
      @screen_data = ::XCB::Screen.new(screen_ptr)
    end
    
    # Ruby-style accessors
    def width
      @screen_data[:width_in_pixels]
    end
    
    def height
      @screen_data[:height_in_pixels]
    end
    
    def depth
      @screen_data[:root_depth]
    end
    
    def root_window
      @screen_data[:root]
    end
    
    def white_pixel
      @screen_data[:white_pixel]
    end
    
    def black_pixel
      @screen_data[:black_pixel]
    end
    
    def root_visual
      @screen_data[:root_visual]
    end
    
    def default_colormap
      @screen_data[:default_colormap]
    end
    
    # Convenience methods
    def dimensions
      [width, height]
    end
    
    def size
      "#{width}x#{height}"
    end
    
    def create_window(options = {})
      Window.new(@connection, self, options)
    end
    
    def create_colormap(visual = nil)
      Colormap.new(@connection, self, visual || root_visual)
    end
    
    def inspect
      "#<XCB::ScreenWrapper #{size} depth=#{depth}>"
    end
  end
end