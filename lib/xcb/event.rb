module XCB
  class Event
    attr_reader :event_ptr, :type
    
    # Event type constants
    TYPES = {
      2 => :key_press,
      3 => :key_release, 
      4 => :button_press,
      5 => :button_release,
      6 => :motion_notify,
      12 => :expose
    }.freeze
    
    def initialize(event_ptr)
      @event_ptr = event_ptr
      @generic_event = XCB::GenericEvent.new(event_ptr)
      @type = TYPES[@generic_event[:response_type] & ~0x80] || :unknown
    end
    
    def type
      @type
    end
    
    def key_press?
      @type == :key_press
    end
    
    def key_release?
      @type == :key_release
    end
    
    def button_press?
      @type == :button_press
    end
    
    def button_release?
      @type == :button_release
    end
    
    def motion?
      @type == :motion_notify
    end
    
    def expose?
      @type == :expose
    end
    
    # Event-specific data accessors
    def key_code
      return nil unless key_press? || key_release?
      @event_ptr.get_uint8(1)  # detail field
    end
    
    def button
      return nil unless button_press? || button_release?
      @event_ptr.get_uint8(1)  # detail field
    end
    
    def x
      case @type
      when :button_press, :button_release, :motion_notify
        @event_ptr.get_int16(24)  # event_x
      else
        nil
      end
    end
    
    def y
      case @type
      when :button_press, :button_release, :motion_notify
        @event_ptr.get_int16(26)  # event_y
      else
        nil
      end
    end
    
    def root_x
      case @type
      when :button_press, :button_release, :motion_notify
        @event_ptr.get_int16(20)  # root_x
      else
        nil
      end
    end
    
    def root_y
      case @type
      when :button_press, :button_release, :motion_notify
        @event_ptr.get_int16(22)  # root_y
      else
        nil
      end
    end
    
    def window_id
      case @type
      when :button_press, :button_release, :motion_notify, :key_press, :key_release
        @event_ptr.get_uint32(12)  # event window
      when :expose
        @event_ptr.get_uint32(4)   # window
      else
        nil
      end
    end
    
    # Expose event specific
    def expose_x
      return nil unless expose?
      @event_ptr.get_int16(8)
    end
    
    def expose_y
      return nil unless expose?
      @event_ptr.get_int16(10)
    end
    
    def expose_width
      return nil unless expose?
      @event_ptr.get_uint16(12)
    end
    
    def expose_height
      return nil unless expose?
      @event_ptr.get_uint16(14)
    end
    
    def expose_count
      return nil unless expose?
      @event_ptr.get_uint16(16)
    end
    
    # Convenience methods
    def position
      return nil unless x && y
      [x, y]
    end
    
    def root_position
      return nil unless root_x && root_y
      [root_x, root_y]
    end
    
    def expose_rect
      return nil unless expose?
      [expose_x, expose_y, expose_width, expose_height]
    end
    
    def to_h
      data = { type: @type }
      
      case @type
      when :key_press, :key_release
        data[:key_code] = key_code
        data[:window_id] = window_id
      when :button_press, :button_release
        data.merge!(
          button: button,
          x: x, y: y,
          root_x: root_x, root_y: root_y,
          window_id: window_id
        )
      when :motion_notify
        data.merge!(
          x: x, y: y,
          root_x: root_x, root_y: root_y,
          window_id: window_id
        )
      when :expose
        data.merge!(
          x: expose_x, y: expose_y,
          width: expose_width, height: expose_height,
          count: expose_count,
          window_id: window_id
        )
      end
      
      data
    end
    
    def inspect
      "#<XCB::Event #{@type} #{to_h.reject { |k, v| k == :type }}>"
    end
  end
end