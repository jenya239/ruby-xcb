#!/usr/bin/env ruby
# Font test using high-level XCB wrapper

require_relative '../lib/xcb_wrapper'

puts "=== XCB Wrapper Font Test ==="

XCB.connect do |conn|
  screen = conn.default_screen
  puts "✅ Screen: #{screen.size}"
  
  # Create window
  window = screen.create_window(
    x: 100, y: 100,
    width: 500, height: 300,
    background: :white,
    events: [:exposure, :key_press]
  )
  
  window.set_title("Wrapper Font Test")
  puts "✅ Window created"
  
  # Load font
  font = XCB::Font.fixed(conn)
  puts "✅ Font loaded: #{font.inspect}"
  
  # Create graphics context with font
  gc_text = window.create_graphics_context(
    foreground: :black,
    background: :white,
    font: font
  )
  
  gc_white = window.create_graphics_context(foreground: :white)
  
  puts "✅ Graphics contexts with font created"
  
  window.show
  
  # Event loop
  puts "🎯 Window shown - should display text"
  puts "⌨️ Press any key to exit"
  
  window.wait_for_event do |event|
    case event.type
    when :expose
      puts "🖼️ Drawing text..."
      
      # Clear background
      gc_white.fill_rectangle(0, 0, 500, 300)
      
      # Draw text at different positions
      gc_text.draw_text(50, 50, "Hello XCB Wrapper!")
      gc_text.draw_text(50, 80, "Ruby-style high-level API")
      gc_text.draw_text(50, 110, "Font: #{font.name}")
      gc_text.draw_text(50, 140, "Screen: #{screen.size}")
      gc_text.draw_text(50, 170, "abcdefghijklmnopqrstuvwxyz")
      gc_text.draw_text(50, 200, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
      gc_text.draw_text(50, 230, "0123456789 !@#$%^&*()")
      
      puts "   Multiple text lines drawn"
      
    when :key_press
      puts "⌨️ Key pressed: #{event.key_code}"
      :break
    end
  end
end

puts "✅ Font test completed"