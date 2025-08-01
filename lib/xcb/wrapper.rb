# High-level Ruby wrapper for XCB
require_relative 'connection'
require_relative 'screen'
require_relative 'window'
require_relative 'graphics_context'
require_relative 'font'
require_relative 'cursor'
require_relative 'event'

module XCB
  # Convenience class methods for common operations
  class << self
    # Connect to X server with Ruby-style block interface
    def connect(display_name = nil, screen_number = nil, &block)
      connection = Connection.new(display_name, screen_number)
      
      if block_given?
        begin
          result = block.call(connection)
          return result
        ensure
          connection.close
        end
      else
        return connection
      end
    end
    
    # Quick window creation
    def create_window(options = {}, &block)
      connect do |conn|
        screen = conn.default_screen
        window = screen.create_window(options)
        
        if block_given?
          block.call(window)
        else
          return window
        end
      end
    end
    
    # Application-style event loop
    def application(&block)
      connect do |conn|
        app = Application.new(conn)
        block.call(app) if block_given?
      end
    end
  end
  
  # Simple application framework
  class Application
    attr_reader :connection, :screen, :windows
    
    def initialize(connection)
      @connection = connection
      @screen = connection.default_screen
      @windows = []
      @running = false
    end
    
    def create_window(options = {})
      window = @screen.create_window(options)
      @windows << window
      window
    end
    
    def create_font(name)
      Font.load(@connection, name)
    end
    
    def create_cursor(type = :arrow)
      Cursor.new(@connection, type)
    end
    
    def run(&block)
      @running = true
      
      while @running
        event = @connection.wait_for_event
        next unless event
        
        # Dispatch event to appropriate window
        window = find_window_for_event(event)
        
        if block_given?
          result = block.call(event, window)
          break if result == :quit
        end
        
        # Default event handling
        handle_default_events(event, window)
      end
    end
    
    def quit
      @running = false
    end
    
    private
    
    def find_window_for_event(event)
      window_id = event.window_id
      return nil unless window_id
      
      @windows.find { |w| w.window_id == window_id }
    end
    
    def handle_default_events(event, window)
      case event.type
      when :expose
        # Можно добавить автоматическую перерисовку
      end
    end
  end
  
  # DSL для создания окон
  module DSL
    def window(options = {}, &block)
      XCB.create_window(options) do |win|
        win.instance_eval(&block) if block_given?
        win
      end
    end
    
    def application(&block)
      XCB.application(&block)
    end
  end
end

# Extend main object with DSL for convenient scripting
extend XCB::DSL