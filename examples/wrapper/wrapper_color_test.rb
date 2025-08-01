#!/usr/bin/env ruby
# Color test using high-level XCB wrapper

require_relative '../lib/xcb_wrapper'

puts "=== XCB Wrapper Color Test ==="

XCB.connect do |conn|
  screen = conn.default_screen
  puts "✅ Screen: #{screen.size}, depth: #{screen.depth}"
  
  # Create window
  window = screen.create_window(
    x: 100, y: 100,
    width: 400, height: 300,
    background: :white,
    events: [:exposure, :key_press]
  )
  
  window.set_title("Wrapper Color Test")
  puts "✅ Window created: #{window.inspect}"
  
  # Create graphics contexts with different colors
  gc_red = window.create_graphics_context(foreground: :red)
  gc_green = window.create_graphics_context(foreground: :green) 
  gc_blue = window.create_graphics_context(foreground: :blue)
  gc_white = window.create_graphics_context(foreground: :white)
  
  puts "✅ Graphics contexts created"
  
  window.show
  
  # Event loop
  puts "🎯 Window shown - should display colored rectangles"
  puts "⌨️ Press any key to exit"
  
  window.wait_for_event do |event|
    case event.type
    when :expose
      puts "🖼️ Drawing colored rectangles..."
      
      # Clear background
      gc_white.fill_rectangle(0, 0, 400, 300)
      
      # Draw colored rectangles
      gc_red.fill_rectangle(50, 50, 80, 60)
      gc_green.fill_rectangle(150, 50, 80, 60)
      gc_blue.fill_rectangle(250, 50, 80, 60)
      
      puts "   Red: 50,50 80x60"
      puts "   Green: 150,50 80x60"  
      puts "   Blue: 250,50 80x60"
      
    when :key_press
      puts "⌨️ Key pressed: #{event.key_code}"
      :break
    end
  end
end

puts "✅ Color test completed"