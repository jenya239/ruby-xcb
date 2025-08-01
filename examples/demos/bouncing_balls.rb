#!/usr/bin/env ruby
# Bouncing Balls - эффектная анимация с физикой в Ruby XCB

require_relative '../../lib/xcb_wrapper'

puts "🎾 Bouncing Balls - Ruby XCB Demo"

XCB.application do |app|
  # Create main window
  canvas = app.create_window(
    x: 100, y: 100,
    width: 600, height: 400,
    background: :black,
    events: [:exposure, :key_press, :button_press]
  )
  
  canvas.set_title("🎾 Ruby XCB Bouncing Balls")
  
  # Create graphics resources
  font = app.create_font("fixed")
  
  graphics = {
    black: canvas.create_graphics_context(foreground: :black),
    white: canvas.create_graphics_context(foreground: :white, font: font),
    red: canvas.create_graphics_context(foreground: :red),
    green: canvas.create_graphics_context(foreground: :green),
    blue: canvas.create_graphics_context(foreground: :blue)
  }
  
  # Ball class for physics
  class Ball
    attr_accessor :x, :y, :vx, :vy, :radius, :color
    
    def initialize(x, y, radius = nil, color = nil)
      @x = x.to_f
      @y = y.to_f
      @radius = radius || (10 + rand(20))  # 10-30 pixel radius
      @color = color || [:red, :green, :blue].sample
      
      # Random velocity
      @vx = (rand - 0.5) * 8  # -4 to +4
      @vy = (rand - 0.5) * 8
      
      # Minimum velocity to keep moving
      @vx = @vx.abs < 1 ? (@vx > 0 ? 2 : -2) : @vx
      @vy = @vy.abs < 1 ? (@vy > 0 ? 2 : -2) : @vy
    end
    
    def update(width, height, gravity = 0.1)
      # Apply gravity
      @vy += gravity
      
      # Update position
      @x += @vx
      @y += @vy
      
      # Bounce off walls with energy loss
      if @x - @radius <= 0 || @x + @radius >= width
        @vx *= -0.9  # 10% energy loss
        @x = @radius if @x - @radius <= 0
        @x = width - @radius if @x + @radius >= width
      end
      
      if @y - @radius <= 0 || @y + @radius >= height
        @vy *= -0.9  # 10% energy loss
        @y = @radius if @y - @radius <= 0
        @y = height - @radius if @y + @radius >= height
      end
      
      # Add some randomness to prevent perfect loops
      if rand(100) == 0
        @vx += (rand - 0.5) * 0.5
        @vy += (rand - 0.5) * 0.5
      end
    end
    
    def draw(graphics)
      # Draw filled circle by drawing multiple rectangles
      (-@radius..@radius).each do |dx|
        (-@radius..@radius).each do |dy|
          if dx*dx + dy*dy <= @radius*@radius
            graphics[@color].fill_rectangle(@x + dx, @y + dy, 1, 1)
          end
        end
      end
    end
    
    def draw_optimized(graphics)
      # Optimized circle drawing with horizontal lines
      (-@radius..@radius).each do |dy|
        width = Math.sqrt(@radius*@radius - dy*dy).to_i
        if width > 0
          graphics[@color].fill_rectangle(@x - width, @y + dy, width * 2, 1)
        end
      end
    end
  end
  
  # Application state
  state = {
    balls: [],
    gravity: 0.15,
    paused: false,
    show_trails: false,
    frame_count: 0
  }
  
  # Add initial balls
  5.times do
    x = 50 + rand(500)
    y = 50 + rand(300)
    state[:balls] << Ball.new(x, y)
  end
  
  def draw_interface(graphics, state)
    g = graphics
    
    # Clear screen
    if state[:show_trails]
      # Fade effect for trails
      g[:black].fill_rectangle(0, 0, 600, 400)
    else
      # Full clear
      g[:black].fill_rectangle(0, 0, 600, 400)
    end
    
    # Draw all balls
    state[:balls].each do |ball|
      ball.draw_optimized(g)
    end
    
    # Draw UI
    g[:white].draw_text(10, 20, "🎾 Bouncing Balls Physics Demo")
    g[:white].draw_text(10, 40, "Balls: #{state[:balls].size} | Gravity: #{state[:gravity].round(2)}")
    
    status = state[:paused] ? "PAUSED" : "Running"
    trails = state[:show_trails] ? "ON" : "OFF"
    g[:white].draw_text(10, 365, "Status: #{status} | Trails: #{trails} | Frame: #{state[:frame_count]}")
    g[:white].draw_text(10, 385, "Click: add ball | SPACE: pause | T: trails | G/H: gravity | C: clear | ESC: exit")
  end
  
  canvas.show
  
  puts "🎾 Bouncing balls physics started!"
  puts "🖱️ Click anywhere to add a new ball"
  puts "⏸️ Press SPACE to pause/resume"
  puts "🌟 Press T to toggle trails effect"
  puts "🌍 Press G/H to decrease/increase gravity"
  puts "🧹 Press C to clear all balls"
  puts "🚪 Press ESC to exit"
  
  # Animation loop
  last_time = Time.now
  target_fps = 60
  frame_time = 1.0 / target_fps
  
  loop do
    current_time = Time.now
    delta_time = current_time - last_time
    
    # Check for events (non-blocking)
    event = app.connection.poll_for_event
    
    if event
      case event.type
      when :expose
        draw_interface(graphics, state)
        
      when :button_press
        x, y = event.position
        if y > 60 && y < 360  # Only add balls in play area
          puts "🎾 New ball added at (#{x}, #{y})"
          state[:balls] << Ball.new(x, y)
          draw_interface(graphics, state)
        end
        
      when :key_press
        case event.key_code
        when 65  # SPACE
          state[:paused] = !state[:paused]
          status = state[:paused] ? "paused" : "resumed"
          puts "⏸️ Animation #{status}"
          draw_interface(graphics, state)
          
        when 28  # T
          state[:show_trails] = !state[:show_trails]
          trails = state[:show_trails] ? "enabled" : "disabled"
          puts "🌟 Trails #{trails}"
          draw_interface(graphics, state)
          
        when 42  # G
          state[:gravity] = [state[:gravity] - 0.05, 0].max
          puts "🌍 Gravity decreased to #{state[:gravity].round(2)}"
          draw_interface(graphics, state)
          
        when 43  # H
          state[:gravity] = [state[:gravity] + 0.05, 1.0].min
          puts "🌍 Gravity increased to #{state[:gravity].round(2)}"
          draw_interface(graphics, state)
          
        when 54  # C
          state[:balls].clear
          puts "🧹 All balls cleared"
          draw_interface(graphics, state)
          
        when 9   # ESC
          puts "🚪 Exiting bouncing balls demo"
          break
        end
      end
    end
    
    # Animation update
    if delta_time >= frame_time && !state[:paused]
      # Update physics
      state[:balls].each do |ball|
        ball.update(600, 400, state[:gravity])
      end
      
      # Remove very slow balls to prevent buildup
      state[:balls].reject! do |ball|
        ball.vx.abs < 0.1 && ball.vy.abs < 0.1 && ball.y > 380
      end
      
      # Redraw
      draw_interface(graphics, state)
      state[:frame_count] += 1
      last_time = current_time
    end
    
    # Small sleep to prevent busy waiting
    sleep(0.001)
  end
end

puts "✅ Bouncing balls demo completed!"