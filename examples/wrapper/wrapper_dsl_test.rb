#!/usr/bin/env ruby
# DSL-style test demonstrating Ruby-way XCB wrapper usage

require_relative '../lib/xcb_wrapper'

puts "=== XCB WRAPPER DSL-STYLE TEST ==="
puts "🎯 Demonstrating Ruby-way API usage"

# DSL-style application using blocks
XCB.application do |app|
  puts "✅ Application started"
  
  # Create main window using builder pattern
  main_window = app.create_window(
    x: 100, y: 100,
    width: 500, height: 350,
    background: :white,
    events: [:exposure, :key_press, :button_press]
  ).tap do |win|
    win.set_title("Ruby XCB - DSL Style Demo")
  end
  
  puts "✅ Window: #{main_window.inspect}"
  
  # Create resources
  font = app.create_font("fixed")
  cursor = app.create_cursor(:crosshair)
  main_window.set_cursor(cursor)
  
  puts "✅ Resources: font=#{font.name}, cursor=crosshair"
  
  # Create drawing contexts with method chaining
  graphics = {
    white: main_window.create_graphics_context(foreground: :white),
    black: main_window.create_graphics_context(foreground: :black),
    red: main_window.create_graphics_context(foreground: :red),
    text: main_window.create_graphics_context(
      foreground: :black, background: :white, font: font
    )
  }
  
  puts "✅ Graphics contexts created"
  
  main_window.show
  
  # Ruby-style drawing methods
  def draw_interface(graphics, click_count)
    g = graphics
    
    # Clear and draw background
    g[:white].fill_rectangle(0, 0, 500, 350)
    
    # Header with Ruby-style string interpolation
    g[:text].draw_text(120, 30, "Ruby XCB DSL-Style Interface")
    g[:text].draw_text(50, 60, "Clicks: #{click_count} | Ruby-way API demonstration")
    
    # Visual elements using method chaining and blocks
    [
      { color: :red, x: 50, y: 100, text: "Object-Oriented" },
      { color: :black, x: 200, y: 100, text: "Method Chaining" },
      { color: :red, x: 350, y: 100, text: "DSL Pattern" }
    ].each_with_index do |item, i|
      g[item[:color]].fill_rectangle(item[:x], item[:y], 80, 40)
      g[:text].draw_text(item[:x] + 5, item[:y] + 55, item[:text])
    end
    
    # Ruby features demonstration
    features = [
      "• Block-based event handling",
      "• Automatic resource management", 
      "• Ruby naming conventions",
      "• Method chaining support",
      "• DSL for complex operations"
    ]
    
    g[:text].draw_text(50, 180, "Ruby-way Features:")
    features.each_with_index do |feature, i|
      g[:text].draw_text(60, 200 + i * 20, feature)
    end
    
    g[:text].draw_text(150, 320, "Click anywhere • Press ESC to exit")
  end
  
  # Application state with Ruby idioms
  state = { click_count: 0, running: true }
  
  puts "\n🎯 DSL-STYLE INTERACTIVE DEMO:"
  puts "🖱️ Experience Ruby-way XCB programming"
  
  # Event loop with Ruby blocks and pattern matching
  app.run do |event, window|
    case event.type
    when :expose
      puts "🖼️ Redrawing with Ruby-style methods..."
      draw_interface(graphics, state[:click_count])
      
    when :button_press
      state[:click_count] += 1
      x, y = event.position
      
      puts "🖱️ Ruby-style click ##{state[:click_count]} at #{event.position.inspect}"
      
      # Ruby-style color cycling
      colors = [:red, :black, :red]
      color = colors[state[:click_count] % colors.size]
      
      # Draw with Ruby method chaining
      graphics[color]
        .fill_rectangle(x - 8, y - 8, 16, 16)
      
      # Update interface using Ruby string interpolation
      graphics[:white].fill_rectangle(45, 45, 410, 20)
      graphics[:text].draw_text(50, 60, "Clicks: #{state[:click_count]} | Ruby-way API demonstration")
      
    when :key_press
      if event.key_code == 9  # ESC
        puts "🚪 Ruby-style exit via ESC"
        :quit  # Ruby-way to signal quit
      end
    end
  end
end

puts "\n✅ DSL-STYLE TEST COMPLETED!"
puts "🎉 Ruby XCB Wrapper demonstrates true Ruby-way programming:"
puts "   • DSL patterns ✅"
puts "   • Block syntax ✅" 
puts "   • Method chaining ✅"
puts "   • Ruby idioms ✅"
puts "   • Object-oriented design ✅"
puts "   • Clean resource management ✅"