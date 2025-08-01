module XCB
  class Window
    attr_reader :connection, :screen, :window_id
    
    DEFAULT_OPTIONS = {
      x: 0,
      y: 0, 
      width: 400,
      height: 300,
      border_width: 1,
      window_class: :input_output,
      background: :white,
      events: [:exposure, :key_press]
    }.freeze
    
    def initialize(connection, screen, options = {})
      @connection = connection
      @screen = screen
      @options = DEFAULT_OPTIONS.merge(options)
      @window_id = connection.generate_id
      @graphics_contexts = []
      
      create_window
      connection.send(:register_resource, self)
    end
    
    # Window management
    def show
      XCB.xcb_map_window(@connection.connection, @window_id)
      @connection.flush
      self
    end
    alias_method :map, :show
    
    def hide
      XCB.xcb_unmap_window(@connection.connection, @window_id)
      @connection.flush
      self
    end
    alias_method :unmap, :hide
    
    def move(x, y)
      configure(x: x, y: y)
    end
    
    def resize(width, height)
      configure(width: width, height: height)
    end
    
    def configure(options = {})
      mask = 0
      values = []
      
      if options[:x]
        mask |= 1  # XCB_CONFIG_WINDOW_X
        values << options[:x]
      end
      
      if options[:y]
        mask |= 2  # XCB_CONFIG_WINDOW_Y
        values << options[:y]
      end
      
      if options[:width]
        mask |= 4  # XCB_CONFIG_WINDOW_WIDTH
        values << options[:width]
      end
      
      if options[:height]
        mask |= 8  # XCB_CONFIG_WINDOW_HEIGHT
        values << options[:height]
      end
      
      if values.any?
        values_ptr = FFI::MemoryPointer.new(:uint32, values.size)
        values.each_with_index { |val, i| values_ptr[i].write_uint32(val) }
        
        XCB.xcb_configure_window(@connection.connection, @window_id, mask, values_ptr)
        @connection.flush
      end
      
      self
    end
    
    def set_cursor(cursor)
      cursor_id = cursor.respond_to?(:cursor_id) ? cursor.cursor_id : cursor
      cursor_vals = FFI::MemoryPointer.new(:uint32, 1)
      cursor_vals.write(:uint32, cursor_id)
      
      XCB.xcb_change_window_attributes(@connection.connection, @window_id, 
                                       XCB::XCB_CW_CURSOR, cursor_vals)
      @connection.flush
      self
    end
    
    def set_title(title)
      XCB.xcb_change_property(@connection.connection, 0, @window_id, 39, 31, 8, 
                              title.length, title)
      @connection.flush
      self
    end
    
    # Graphics operations
    def clear(color = :white)
      XCB.xcb_clear_area(@connection.connection, 0, @window_id, 0, 0, 
                         @options[:width], @options[:height])
      @connection.flush
      self
    end
    
    def create_graphics_context(options = {})
      gc = GraphicsContext.new(@connection, self, options)
      @graphics_contexts << gc
      gc
    end
    
    # Event handling
    def wait_for_event(&block)
      @connection.event_loop do |event|
        if belongs_to_window?(event)
          result = block.call(event)
          result == :break ? :break : :continue
        else
          :continue
        end
      end
    end
    
    def cleanup
      @graphics_contexts.each(&:cleanup)
      @graphics_contexts.clear
      
      XCB.xcb_destroy_window(@connection.connection, @window_id) rescue nil
    end
    
    def inspect
      "#<XCB::Window id=#{@window_id} #{@options[:width]}x#{@options[:height]}>"
    end
    
    private
    
    def create_window
      # Prepare values
      mask = 0
      values = []
      
      # Background
      if @options[:background]
        mask |= XCB::XCB_CW_BACK_PIXEL
        values << background_pixel(@options[:background])
      end
      
      # Events
      if @options[:events]
        mask |= XCB::XCB_CW_EVENT_MASK
        values << event_mask(@options[:events])
      end
      
      # Create values array
      values_ptr = FFI::MemoryPointer.new(:uint32, values.size)
      values.each_with_index { |val, i| values_ptr[i].write_uint32(val) }
      
      # Create window
      XCB.xcb_create_window(
        @connection.connection,
        XCB::XCB_COPY_FROM_PARENT,  # depth
        @window_id,
        @screen.root_window,
        @options[:x], @options[:y],
        @options[:width], @options[:height],
        @options[:border_width],
        window_class_value(@options[:window_class]),
        @screen.root_visual,
        mask,
        values_ptr
      )
    end
    
    def background_pixel(color)
      case color
      when :white then @screen.white_pixel
      when :black then @screen.black_pixel
      when Integer then color
      else @screen.white_pixel
      end
    end
    
    def window_class_value(window_class)
      case window_class
      when :input_output then XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT
      when :input_only then XCB::XCB_WINDOW_CLASS_INPUT_ONLY
      else XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT
      end
    end
    
    def event_mask(events)
      mask = 0
      events.each do |event|
        mask |= case event
                when :exposure then XCB::XCB_EVENT_MASK_EXPOSURE
                when :key_press then XCB::XCB_EVENT_MASK_KEY_PRESS
                when :button_press then XCB::XCB_EVENT_MASK_BUTTON_PRESS
                when :button_release then XCB::XCB_EVENT_MASK_BUTTON_RELEASE
                when :motion_notify then XCB::XCB_EVENT_MASK_POINTER_MOTION
                else 0
                end
      end
      mask
    end
    
    def belongs_to_window?(event)
      # Simplified - в реальной реализации нужно проверять window ID в событии
      true
    end
  end
end