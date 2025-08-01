#!/usr/bin/env ruby
# Simple test of high-level XCB wrapper

require_relative '../lib/xcb_wrapper'

puts "=== XCB Wrapper Simple Test ==="

# Test 1: Basic connection and window
puts "\n1. Testing basic connection and window creation..."

XCB.connect do |conn|
  puts "✅ Connected to X server"
  puts "   Screen: #{conn.default_screen.size}"
  
  window = conn.default_screen.create_window(
    x: 100, y: 100,
    width: 400, height: 300,
    background: :white,
    events: [:exposure, :key_press, :button_press]
  )
  
  window.set_title("Ruby XCB Wrapper Test")
  window.show
  
  puts "✅ Window created and shown"
  puts "   #{window.inspect}"
  
  # Wait for one event and exit
  event = conn.wait_for_event
  puts "✅ Event received: #{event.inspect}"
end

puts "✅ Test 1 completed - connection closed automatically"