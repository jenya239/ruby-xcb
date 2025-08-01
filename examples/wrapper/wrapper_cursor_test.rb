#!/usr/bin/env ruby
# Cursor test using high-level XCB wrapper

require_relative '../lib/xcb_wrapper'

puts "=== XCB Wrapper Cursor Test ==="

XCB.connect do |conn|
  screen = conn.default_screen
  puts "✅ Screen: #{screen.size}"
  
  # Create window
  window = screen.create_window(
    x: 100, y: 100,
    width: 400, height: 300,
    background: :white,
    events: [:exposure, :key_press, :button_press]
  )
  
  window.set_title("Wrapper Cursor Test")
  puts "✅ Window created"
  
  # Create crosshair cursor
  cursor = XCB::Cursor.crosshair(conn)
  puts "✅ Crosshair cursor created: #{cursor.inspect}"
  
  # Set cursor for window
  window.set_cursor(cursor)
  puts "✅ Cursor set for window"
  
  # Create graphics context for drawing
  gc_black = window.create_graphics_context(foreground: :black)
  gc_white = window.create_graphics_context(foreground: :white)
  
  window.show
  
  # Event loop
  puts "🎯 Window shown - cursor should be crosshair"
  puts "🖱️ Move mouse over window to see cursor"
  puts "🖱️ Click to draw lines, press key to exit"
  
  lines = []
  
  window.wait_for_event do |event|
    case event.type
    when :expose
      puts "🖼️ Redrawing window..."
      
      # Clear background
      gc_white.fill_rectangle(0, 0, 400, 300)
      
      # Draw frame
      gc_black.draw_rectangle(10, 10, 380, 280)
      
      # Draw all lines
      lines.each do |line|
        gc_black.draw_line(line[:x1], line[:y1], line[:x2], line[:y2])
      end
      
      puts "   Frame and #{lines.size} lines drawn"
      
    when :button_press
      x, y = event.position
      puts "🖱️ Click at (#{x}, #{y})"
      
      # Add line from center to click position
      center_x, center_y = 200, 150
      lines << { x1: center_x, y1: center_y, x2: x, y2: y }
      
      # Redraw immediately
      gc_black.draw_line(center_x, center_y, x, y)
      
    when :key_press
      puts "⌨️ Key pressed: #{event.key_code}"
      :break
    end
  end
end

puts "✅ Cursor test completed"