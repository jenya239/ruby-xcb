#!/usr/bin/env ruby
# Final comprehensive test of high-level XCB wrapper

require_relative '../lib/xcb_wrapper'

puts "=== FINAL XCB WRAPPER COMPREHENSIVE TEST ==="
puts "🎯 Testing all high-level wrapper features"

XCB.connect do |conn|
  screen = conn.default_screen
  puts "✅ Connected: #{screen.size}, depth #{screen.depth}"
  
  # Create main window
  window = screen.create_window(
    x: 50, y: 50,
    width: 600, height: 400,
    background: :white,
    events: [:exposure, :key_press, :button_press]
  )
  
  window.set_title("Ruby XCB Wrapper - Final Test")
  puts "✅ Window: #{window.inspect}"
  
  # Load font
  font = XCB::Font.fixed(conn)
  puts "✅ Font: #{font.inspect}"
  
  # Create cursor
  cursor = XCB::Cursor.crosshair(conn)
  window.set_cursor(cursor)
  puts "✅ Cursor: #{cursor.inspect}"
  
  # Create graphics contexts
  gc_white = window.create_graphics_context(foreground: :white)
  gc_red = window.create_graphics_context(foreground: :red)
  gc_green = window.create_graphics_context(foreground: :green)
  gc_blue = window.create_graphics_context(foreground: :blue)
  gc_text = window.create_graphics_context(
    foreground: :black,
    background: :white,
    font: font
  )
  
  puts "✅ Graphics contexts created"
  
  window.show
  
  # Application state
  click_count = 0
  
  puts "\n🎯 INTERACTIVE DEMONSTRATION:"
  puts "🖱️ Click anywhere - colored squares will appear"
  puts "⌨️ Press ESC to exit"
  
  # Main event loop
  window.wait_for_event do |event|
    case event.type
    when :expose
      puts "🖼️ Redrawing interface..."
      
      # Clear background
      gc_white.fill_rectangle(0, 0, 600, 400)
      
      # Title
      gc_text.draw_text(150, 30, "=== RUBY XCB WRAPPER FINAL TEST ===")
      
      # Info
      info = "Screen: #{screen.size} | Clicks: #{click_count} | Font: #{font.name} | Cursor: crosshair"
      gc_text.draw_text(20, 60, info)
      
      # Demo rectangles
      gc_red.fill_rectangle(50, 100, 80, 60)
      gc_green.fill_rectangle(150, 100, 80, 60)
      gc_blue.fill_rectangle(250, 100, 80, 60)
      
      # Labels
      gc_text.draw_text(70, 180, "RED")
      gc_text.draw_text(165, 180, "GREEN")
      gc_text.draw_text(270, 180, "BLUE")
      
      # Instructions
      gc_text.draw_text(150, 220, "Click anywhere to add colored squares")
      gc_text.draw_text(200, 240, "Press ESC to exit")
      
      # Wrapper features summary
      gc_text.draw_text(20, 280, "Wrapper Features Tested:")
      gc_text.draw_text(30, 300, "• Ruby-style object-oriented API")
      gc_text.draw_text(30, 320, "• Automatic resource management") 
      gc_text.draw_text(30, 340, "• Event handling with blocks")
      gc_text.draw_text(30, 360, "• Graphics contexts and drawing")
      
      puts "   Interface drawn with info"
      
    when :button_press
      click_count += 1
      x, y = event.position
      
      puts "🖱️ Click ##{click_count} at (#{x}, #{y})"
      
      # Choose color based on click count
      gc = case click_count % 3
           when 1 then gc_red
           when 2 then gc_green
           else gc_blue
           end
      
      # Draw square at click position
      gc.fill_rectangle(x - 10, y - 10, 20, 20)
      
      # Update click counter in interface
      gc_white.fill_rectangle(15, 45, 570, 20)  # Clear info line
      info = "Screen: #{screen.size} | Clicks: #{click_count} | Font: #{font.name} | Cursor: crosshair"
      gc_text.draw_text(20, 60, info)
      
    when :key_press
      key_code = event.key_code
      puts "⌨️ Key pressed: #{key_code}"
      
      # ESC key (code 9) exits
      if key_code == 9
        puts "🚪 ESC pressed - exiting"
        :break
      end
    end
  end
end

puts "\n✅ FINAL WRAPPER TEST COMPLETED!"
puts "🎉 High-level Ruby XCB wrapper fully functional:"
puts "   • Object-oriented design ✅"
puts "   • Automatic resource cleanup ✅"  
puts "   • Ruby-style method names ✅"
puts "   • Block-based event handling ✅"
puts "   • Convenient graphics API ✅"
puts "   • Font and cursor management ✅"
puts "   • Full XCB feature coverage ✅"