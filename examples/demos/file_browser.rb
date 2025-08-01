#!/usr/bin/env ruby
# Simple File Browser - демонстрация файлового навигатора с Ruby XCB

require_relative '../../lib/xcb_wrapper'  
require 'pathname'

puts "📁 Simple File Browser - Ruby XCB Demo"

XCB.application do |app|
  # Create main window
  browser = app.create_window(
    x: 100, y: 100,
    width: 500, height: 400, 
    background: :white,
    events: [:exposure, :key_press, :button_press]
  )
  
  browser.set_title("📁 Ruby XCB File Browser")
  
  # Create graphics resources
  font = app.create_font("fixed")
  
  graphics = {
    white: browser.create_graphics_context(foreground: :white, font: font),
    black: browser.create_graphics_context(foreground: :black, font: font),
    blue: browser.create_graphics_context(foreground: :blue, font: font),
    green: browser.create_graphics_context(foreground: :green, font: font)
  }
  
  # Application state
  state = {
    current_path: Pathname.pwd,
    entries: [],
    selected_index: 0,
    scroll_offset: 0
  }
  
  def load_directory(path)
    begin
      entries = []
      
      # Add parent directory if not root
      unless path.root?
        entries << { name: "..", type: :parent, path: path.parent }
      end
      
      # Load directory contents
      Dir.entries(path).sort.each do |entry|
        next if entry.start_with?('.')
        
        full_path = path + entry
        
        if full_path.directory?
          entries << { name: entry, type: :directory, path: full_path }
        elsif full_path.file?
          entries << { name: entry, type: :file, path: full_path }
        end
      rescue Errno::EACCES
        # Skip files we can't access
        next
      end
      
      entries
    rescue Errno::EACCES => e
      puts "⚠️ Access denied: #{path}"
      []
    rescue => e
      puts "⚠️ Error loading directory: #{e.message}"
      []
    end
  end
  
  def draw_interface(graphics, state)
    g = graphics
    
    # Clear window
    g[:white].fill_rectangle(0, 0, 500, 400)
    
    # Header
    g[:black].draw_text(10, 20, "📁 File Browser")
    
    # Current path
    path_text = "Path: #{state[:current_path]}"
    if path_text.length > 60
      path_text = "Path: ...#{path_text[-55..-1]}"
    end
    g[:blue].draw_text(10, 40, path_text)
    
    # Instructions
    g[:black].draw_text(10, 365, "Click to navigate | ↑↓: select | Enter: open | Backspace: up | ESC: exit")
    
    # File list
    visible_entries = 18  # Lines that fit in the window
    start_y = 60
    line_height = 16
    
    state[:entries].each_with_index do |entry, index|
      next if index < state[:scroll_offset]
      break if index >= state[:scroll_offset] + visible_entries
      
      y = start_y + (index - state[:scroll_offset]) * line_height
      
      # Selection highlight
      if index == state[:selected_index]
        g[:blue].fill_rectangle(8, y - 12, 484, 14)
        text_color = :white
      else
        text_color = :black
      end
      
      # Entry icon and name
      case entry[:type]
      when :parent
        icon = "⬆️"
        name_color = :blue
      when :directory
        icon = "📁"
        name_color = :blue
      when :file
        icon = "📄"
        name_color = :black
      end
      
      # Draw entry
      if index == state[:selected_index]
        g[:white].draw_text(15, y, "#{icon} #{entry[:name]}")
        
        # File info (size for files)
        if entry[:type] == :file
          begin
            size = entry[:path].size
            size_text = format_size(size)
            g[:white].draw_text(400, y, size_text)
          rescue
            # Skip if can't get size
          end
        end
      else
        g[:black].draw_text(15, y, "#{icon} #{entry[:name]}")
        
        # File info (size for files)
        if entry[:type] == :file
          begin
            size = entry[:path].size
            size_text = format_size(size)
            g[:black].draw_text(400, y, size_text)
          rescue
            # Skip if can't get size
          end
        end
      end
    end
    
    # Scrollbar indicator
    if state[:entries].size > visible_entries
      total_height = 280
      scrollbar_height = (visible_entries.to_f / state[:entries].size * total_height).to_i
      scrollbar_y = 60 + (state[:scroll_offset].to_f / state[:entries].size * total_height).to_i
      
      g[:black].fill_rectangle(490, scrollbar_y, 8, scrollbar_height)
    end
  end
  
  def format_size(size)
    return "0 B" if size == 0
    
    units = ['B', 'KB', 'MB', 'GB']
    unit_index = 0
    size_f = size.to_f
    
    while size_f >= 1024 && unit_index < units.length - 1
      size_f /= 1024
      unit_index += 1
    end
    
    "#{size_f.round(1)} #{units[unit_index]}"
  end
  
  def handle_click(state, x, y)
    # Check if click is in file list area
    return unless y >= 60 && y <= 340
    
    # Calculate clicked entry
    line_height = 16
    clicked_line = (y - 60) / line_height + state[:scroll_offset]
    
    return unless clicked_line < state[:entries].size
    
    # Select and open entry
    state[:selected_index] = clicked_line
    open_selected_entry(state)
  end
  
  def open_selected_entry(state)
    return if state[:entries].empty?
    
    entry = state[:entries][state[:selected_index]]
    
    case entry[:type]
    when :parent, :directory
      puts "📂 Opening directory: #{entry[:path]}"
      state[:current_path] = entry[:path]
      state[:entries] = load_directory(state[:current_path])
      state[:selected_index] = 0
      state[:scroll_offset] = 0
    when :file
      puts "📄 File: #{entry[:name]} (#{format_size(entry[:path].size)})"
    end
  end
  
  def move_selection(state, direction)
    case direction
    when :up
      state[:selected_index] = [state[:selected_index] - 1, 0].max
    when :down
      state[:selected_index] = [state[:selected_index] + 1, state[:entries].size - 1].min
    end
    
    # Auto-scroll
    visible_entries = 18
    if state[:selected_index] < state[:scroll_offset]
      state[:scroll_offset] = state[:selected_index]
    elsif state[:selected_index] >= state[:scroll_offset] + visible_entries
      state[:scroll_offset] = state[:selected_index] - visible_entries + 1
    end
  end
  
  def go_up_directory(state)
    unless state[:current_path].root?
      puts "⬆️ Going up to parent directory"
      state[:current_path] = state[:current_path].parent
      state[:entries] = load_directory(state[:current_path])
      state[:selected_index] = 0
      state[:scroll_offset] = 0
    end
  end
  
  # Initialize
  state[:entries] = load_directory(state[:current_path])
  
  browser.show
  
  puts "📁 File browser started!"
  puts "📂 Current directory: #{state[:current_path]}"
  puts "🖱️ Click on folders/files to navigate"
  puts "⌨️ Use arrow keys to navigate, Enter to open"
  puts "🔙 Backspace to go up, ESC to exit"
  
  # Main event loop
  app.run do |event, window|
    case event.type
    when :expose
      draw_interface(graphics, state)
      
    when :button_press
      x, y = event.position
      puts "🖱️ Click at (#{x}, #{y})"
      handle_click(state, x, y)
      draw_interface(graphics, state)
      
    when :key_press
      case event.key_code
      when 111  # Up arrow
        move_selection(state, :up)
        puts "⬆️ Selected: #{state[:entries][state[:selected_index]][:name]}"
        draw_interface(graphics, state)
        
      when 116  # Down arrow  
        move_selection(state, :down)
        puts "⬇️ Selected: #{state[:entries][state[:selected_index]][:name]}"
        draw_interface(graphics, state)
        
      when 36   # Enter
        puts "📂 Opening: #{state[:entries][state[:selected_index]][:name]}"
        open_selected_entry(state)
        draw_interface(graphics, state)
        
      when 22   # Backspace
        go_up_directory(state)
        draw_interface(graphics, state)
        
      when 9    # ESC
        puts "🚪 Exiting file browser"
        :quit
      end
    end
  end
end

puts "✅ File browser demo completed!"