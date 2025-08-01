module XCB
  class Connection
    attr_reader :connection, :screens
    
    def initialize(display_name = nil, screen_number = nil)
      @connection = connect_to_display(display_name, screen_number)
      raise XCBError, "Failed to connect to X server" if connection_has_error?
      
      @screens = load_screens
      @resources = []
      
      # Автоматическая очистка при завершении
      ObjectSpace.define_finalizer(self, self.class.finalize(@connection, @resources))
    end
    
    def screen(number = 0)
      @screens[number] || @screens.first
    end
    
    def default_screen
      screen(0)
    end
    
    def generate_id
      XCB.xcb_generate_id(@connection)
    end
    
    def flush
      XCB.xcb_flush(@connection)
    end
    
    def wait_for_event
      event_ptr = XCB.xcb_wait_for_event(@connection)
      return nil if event_ptr.null?
      
      Event.new(event_ptr)
    end
    
    def poll_for_event
      event_ptr = XCB.xcb_poll_for_event(@connection)
      return nil if event_ptr.null?
      
      Event.new(event_ptr)
    end
    
    # Ruby-style event loop with block
    def event_loop(&block)
      while event = wait_for_event
        result = block.call(event)
        break if result == :break
      end
    end
    
    def close
      cleanup_resources
      XCB.xcb_disconnect(@connection) unless @connection.null?
      @connection = FFI::Pointer::NULL
    end
    
    private
    
    def connect_to_display(display_name, screen_number)
      if screen_number
        screen_ptr = FFI::MemoryPointer.new(:int)
        screen_ptr.write_int(screen_number)
      else
        screen_ptr = FFI::MemoryPointer.new(:int)
      end
      
      conn = XCB.xcb_connect(display_name, screen_ptr)
      @screen_number = screen_ptr.read_int if screen_ptr
      conn
    end
    
    def connection_has_error?
      XCB.xcb_connection_has_error(@connection) != 0
    end
    
    def load_screens
      setup = XCB.xcb_get_setup(@connection)
      screen_iter = XCB.xcb_setup_roots_iterator(setup)
      
      screens = []
      screens << ScreenWrapper.new(self, screen_iter[:data])
      screens
    end
    
    def register_resource(resource)
      @resources << resource
    end
    
    def cleanup_resources
      @resources.each(&:cleanup) rescue nil
      @resources.clear
    end
    
    def self.finalize(connection, resources)
      proc do
        resources.each(&:cleanup) rescue nil
        XCB.xcb_disconnect(connection) unless connection.null?
      end
    end
  end
  
  class XCBError < StandardError; end
end