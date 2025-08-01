#!/usr/bin/env ruby
# Simple Paint Application - демонстрация возможностей Ruby XCB Wrapper

require_relative '../../lib/xcb_wrapper'

puts "🎨 Simple Paint - Ruby XCB Demo"

XCB.application do |app|
  # Create main window
  canvas = app.create_window(
    x: 100, y: 100, 
    width: 600, height: 400,
    background: :white,
    events: [:exposure, :button_press, :button_release, :motion_notify, :key_press]
  )
  
  canvas.set_title("🎨 Simple Paint - Ruby XCB")
  
  # Create tools
  font = app.create_font("fixed")
  cursor = app.create_cursor(:crosshair)
  canvas.set_cursor(cursor)
  
  # Graphics contexts for different colors
  brushes = {
    white: canvas.create_graphics_context(foreground: :white),
    black: canvas.create_graphics_context(foreground: :black),
    red: canvas.create_graphics_context(foreground: :red),
    green: canvas.create_graphics_context(foreground: :green),
    blue: canvas.create_graphics_context(foreground: :blue),
    text: canvas.create_graphics_context(foreground: :black, font: font)
  }
  
  # Application state
  state = {
    drawing: false,
    current_color: :black,
    last_x: nil,
    last_y: nil,
    strokes: []
  }
  
  colors = [:black, :red, :green, :blue]
  
  # Helper methods
  def draw_ui(brushes, current_color)
    # Clear UI area
    brushes[:white].fill_rectangle(0, 0, 600, 40)
    
    # Title
    brushes[:text].draw_text(10, 20, "🎨 Simple Paint")
    
    # Color palette
    colors = [:black, :red, :green, :blue]
    colors.each_with_index do |color, i|
      x = 150 + i * 60
      
      # Color square
      brushes[color].fill_rectangle(x, 5, 30, 30)
      
      # Selection indicator
      if color == current_color
        brushes[:black].draw_rectangle(x-2, 3, 34, 34)
      end
    end
    
    # Instructions
    brushes[:text].draw_text(450, 20, "1-4: colors, C: clear, ESC: exit")
  end
  
  def draw_stroke(brushes, color, x1, y1, x2, y2)
    brushes[color].draw_line(x1, y1, x2, y2)
  end
  
  canvas.show
  puts "🎨 Paint application started!"
  puts "🖱️ Drag to draw"
  puts "🎨 Press 1-4 to change colors"
  puts "🧹 Press C to clear"
  puts "🚪 Press ESC to exit"
  
  # Main event loop
  app.run do |event, window|
    case event.type
    when :expose
      # Redraw everything
      draw_ui(brushes, state[:current_color])
      
      # Redraw all strokes
      state[:strokes].each do |stroke|
        draw_stroke(brushes, stroke[:color], 
                   stroke[:x1], stroke[:y1], stroke[:x2], stroke[:y2])
      end
      
    when :button_press
      if event.y > 40  # Drawing area only
        state[:drawing] = true
        state[:last_x] = event.x
        state[:last_y] = event.y
        puts "🖊️ Start drawing at (#{event.x}, #{event.y})"
      end
      
    when :button_release
      state[:drawing] = false
      state[:last_x] = nil
      state[:last_y] = nil
      puts "🖊️ Stop drawing"
      
    when :motion_notify
      if state[:drawing] && state[:last_x] && state[:last_y]
        x, y = event.x, event.y
        
        if y > 40  # Stay in drawing area
          # Draw line
          draw_stroke(brushes, state[:current_color], 
                     state[:last_x], state[:last_y], x, y)
          
          # Save stroke
          state[:strokes] << {
            color: state[:current_color],
            x1: state[:last_x], y1: state[:last_y],
            x2: x, y2: y
          }
          
          # Update position
          state[:last_x] = x
          state[:last_y] = y
        end
      end
      
    when :key_press
      case event.key_code
      when 10..13  # Keys 1-4
        color_index = event.key_code - 10
        if color_index < colors.size
          state[:current_color] = colors[color_index]
          puts "🎨 Color changed to #{state[:current_color]}"
          draw_ui(brushes, state[:current_color])
        end
        
      when 54  # Key C
        puts "🧹 Canvas cleared"
        state[:strokes].clear
        brushes[:white].fill_rectangle(0, 40, 600, 360)
        draw_ui(brushes, state[:current_color])
        
      when 9  # ESC
        puts "🚪 Exiting paint application"
        :quit
      end
    end
  end
end

puts "✅ Simple Paint demo completed!"