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
    line_width: 1,
    chaos_mode: false,
    last_x: nil,
    last_y: nil,
    strokes: []
  }
  
  colors = [:black, :red, :green, :blue]
  line_widths = [1, 3, 5, 8]
  
  # Helper methods
  def draw_ui(brushes, current_color, line_width, chaos_mode)
    # Clear UI area
    brushes[:white].fill_rectangle(0, 0, 600, 60)
    
    # Title with chaos indicator
    title = chaos_mode ? "🎨 Simple Paint 🌀 CHAOS MODE" : "🎨 Simple Paint"
    brushes[:text].draw_text(10, 20, title)
    
    unless chaos_mode
      # Color palette (only show in normal mode)
      colors = [:black, :red, :green, :blue]
      colors.each_with_index do |color, i|
        x = 150 + i * 40
        
        # Color square
        brushes[color].fill_rectangle(x, 5, 20, 20)
        
        # Selection indicator
        if color == current_color
          brushes[:black].draw_rectangle(x-2, 3, 24, 24)
        end
      end
      
      # Line width samples (only show in normal mode)
      line_widths = [1, 3, 5, 8]
      line_widths.each_with_index do |width, i|
        x = 320 + i * 35
        
        # Draw line sample
        brushes[:black].set_line_width(width)
        brushes[:black].draw_line(x, 12, x + 15, 12)
        
        # Selection indicator
        if width == line_width
          brushes[:black].set_line_width(1)
          brushes[:black].draw_rectangle(x-2, 3, 19, 18)
        end
      end
      
      # Reset line width
      brushes[:black].set_line_width(1)
    else
      # Chaos mode indicator
      brushes[:text].draw_text(200, 20, "🌀 Random colors & widths!")
    end
    
    # Instructions
    mode_text = chaos_mode ? "CHAOS" : "#{line_width}px"
    brushes[:text].draw_text(10, 40, "1-4: colors | Q-T: width (#{mode_text}) | SPACE: chaos | C: clear | ESC: exit")
  end
  
  def draw_stroke(brushes, color, width, x1, y1, x2, y2)
    brushes[color].set_line_width(width)
    brushes[color].draw_line(x1, y1, x2, y2)
  end
  
  canvas.show
  puts "🎨 Paint application started!"
  puts "🖱️ Drag to draw"
  puts "🎨 Press 1-4 to change colors"
  puts "📏 Press Q-T to change line width"
  puts "🌀 Press SPACE for chaos mode"
  puts "🧹 Press C to clear"
  puts "🚪 Press ESC to exit"
  
  # Main event loop
  app.run do |event, window|
    case event.type
    when :expose
      # Redraw everything
      draw_ui(brushes, state[:current_color], state[:line_width], state[:chaos_mode])
      
      # Redraw all strokes
      state[:strokes].each do |stroke|
        draw_stroke(brushes, stroke[:color], stroke[:width],
                   stroke[:x1], stroke[:y1], stroke[:x2], stroke[:y2])
      end
      
    when :button_press
      if event.y > 60  # Drawing area only (increased UI height)
        state[:drawing] = true
        state[:last_x] = event.x
        state[:last_y] = event.y
        
        # Chaos mode: randomize color and width for each stroke
        if state[:chaos_mode]
          state[:current_color] = colors.sample
          state[:line_width] = line_widths.sample
          puts "🌀 Start chaos drawing at (#{event.x}, #{event.y}) [#{state[:current_color]}, #{state[:line_width]}px]"
        else
          puts "🖊️ Start drawing at (#{event.x}, #{event.y}) [#{state[:current_color]}, #{state[:line_width]}px]"
        end
      end
      
    when :button_release
      state[:drawing] = false
      state[:last_x] = nil
      state[:last_y] = nil
      puts "🖊️ Stop drawing"
      
    when :motion_notify
      if state[:drawing] && state[:last_x] && state[:last_y]
        x, y = event.x, event.y
        
        if y > 60  # Stay in drawing area (increased UI height)
          # In chaos mode, change color/width randomly for each segment
          if state[:chaos_mode] && rand(5) == 0  # 20% chance to change
            state[:current_color] = colors.sample
            state[:line_width] = line_widths.sample
          end
          
          # Draw line
          draw_stroke(brushes, state[:current_color], state[:line_width],
                     state[:last_x], state[:last_y], x, y)
          
          # Save stroke
          state[:strokes] << {
            color: state[:current_color],
            width: state[:line_width],
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
      when 10..13  # Keys 1-4 (colors)
        unless state[:chaos_mode]  # Only allow manual color change in normal mode
          color_index = event.key_code - 10
          if color_index < colors.size
            state[:current_color] = colors[color_index]
            puts "🎨 Color changed to #{state[:current_color]}"
            draw_ui(brushes, state[:current_color], state[:line_width], state[:chaos_mode])
          end
        end
        
      when 24..27  # Keys Q-T (line widths: Q=24, W=25, E=26, T=28)  
        unless state[:chaos_mode]  # Only allow manual width change in normal mode
          width_index = case event.key_code
                        when 24 then 0  # Q
                        when 25 then 1  # W  
                        when 26 then 2  # E
                        when 28 then 3  # T
                        else -1
                        end
          
          if width_index >= 0 && width_index < line_widths.size
            state[:line_width] = line_widths[width_index]
            puts "📏 Line width changed to #{state[:line_width]}px"
            draw_ui(brushes, state[:current_color], state[:line_width], state[:chaos_mode])
          end
        end
        
      when 65  # SPACE key
        state[:chaos_mode] = !state[:chaos_mode]
        mode_text = state[:chaos_mode] ? "enabled" : "disabled"
        puts "🌀 Chaos mode #{mode_text}"
        draw_ui(brushes, state[:current_color], state[:line_width], state[:chaos_mode])
        
      when 54  # Key C
        puts "🧹 Canvas cleared"
        state[:strokes].clear
        brushes[:white].fill_rectangle(0, 60, 600, 340)
        draw_ui(brushes, state[:current_color], state[:line_width], state[:chaos_mode])
        
      when 9  # ESC
        puts "🚪 Exiting paint application"
        :quit
      end
    end
  end
end

puts "✅ Simple Paint demo completed!"