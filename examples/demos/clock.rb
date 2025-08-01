#!/usr/bin/env ruby
# Digital Clock - демонстрация анимации и таймеров в Ruby XCB

require_relative '../../lib/xcb_wrapper'
require 'time'

puts "🕐 Digital Clock - Ruby XCB Demo"

XCB.application do |app|
  # Create clock window
  clock_window = app.create_window(
    x: 200, y: 200,
    width: 300, height: 100,
    background: :black,
    events: [:exposure, :key_press]
  )
  
  clock_window.set_title("🕐 Ruby XCB Clock")
  
  # Create graphics resources
  font = app.create_font("fixed")
  
  graphics = {
    black: clock_window.create_graphics_context(foreground: :black),
    green: clock_window.create_graphics_context(foreground: :green, font: font),
    red: clock_window.create_graphics_context(foreground: :red, font: font)
  }
  
  def draw_time(graphics, width, height)
    # Clear window
    graphics[:black].fill_rectangle(0, 0, width, height)
    
    # Get current time
    now = Time.now
    time_str = now.strftime("%H:%M:%S")
    date_str = now.strftime("%Y-%m-%d")
    
    # Calculate text positions (rough centering)
    time_x = (width - time_str.length * 10) / 2
    date_x = (width - date_str.length * 8) / 2
    
    # Draw time (large, green)
    graphics[:green].draw_text(time_x, 40, time_str)
    
    # Draw date (smaller, red)
    graphics[:red].draw_text(date_x, 70, date_str)
  end
  
  clock_window.show
  
  puts "🕐 Digital clock started!"
  puts "⏰ Updates every second"
  puts "🚪 Press any key to exit"
  
  last_second = -1
  
  # Event loop with time checking
  loop do
    # Check for events (non-blocking)
    event = app.connection.poll_for_event
    
    if event
      case event.type
      when :expose
        draw_time(graphics, 300, 100)
        
      when :key_press
        puts "🚪 Clock stopped"
        break
      end
    end
    
    # Update clock every second
    current_second = Time.now.sec
    if current_second != last_second
      draw_time(graphics, 300, 100)
      last_second = current_second
      puts "🕐 Time updated: #{Time.now.strftime('%H:%M:%S')}"
    end
    
    # Small delay to avoid busy waiting
    sleep(0.1)
  end
end

puts "✅ Digital clock demo completed!"