#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Стабильный пиксмап XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

# Получение screen
setup = XCB.xcb_get_setup(conn)
iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(iter[:data])

root = screen[:root]
visual = screen[:root_visual]
root_depth = screen[:root_depth]
white_pixel = screen[:white_pixel]
black_pixel = screen[:black_pixel]

puts "✅ Подключено к экрану: #{screen_ptr.read_int}"
puts "📊 Root depth: #{root_depth}"

# Создание окна с событиями
window_id = XCB.xcb_generate_id(conn)
mask = XCB::XCB_CW_EVENT_MASK
values = FFI::MemoryPointer.new(:uint32, 1)
event_mask = XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS
values.write_array_of_uint32([event_mask])

XCB.xcb_create_window(
  conn, XCB::XCB_COPY_FROM_PARENT, window_id, root,
  100, 100, 300, 300, 1,
  XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT, visual,
  mask, values
)

XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)
puts "✅ Окно 300x300 создано"

# Создание пиксмапа размером с окно
pixmap_id = XCB.xcb_generate_id(conn)
XCB.xcb_create_pixmap(conn, root_depth, pixmap_id, window_id, 300, 300)
puts "✅ Пиксмап 300x300 создан с глубиной #{root_depth}"

# GC для белого фона
gc_bg = XCB.xcb_generate_id(conn)
bg_values = FFI::MemoryPointer.new(:uint32, 1)
bg_values.write_array_of_uint32([white_pixel])
XCB.xcb_create_gc(conn, gc_bg, pixmap_id, XCB::XCB_GC_FOREGROUND, bg_values)

# GC для чёрного прямоугольника
gc_fg = XCB.xcb_generate_id(conn)
fg_values = FFI::MemoryPointer.new(:uint32, 1)
fg_values.write_array_of_uint32([black_pixel])
XCB.xcb_create_gc(conn, gc_fg, pixmap_id, XCB::XCB_GC_FOREGROUND, fg_values)

puts "✅ Созданы два GC"

# Заливка белым фоном всего пиксмапа
full_rect = XCB::Rectangle.new
full_rect[:x] = 0
full_rect[:y] = 0
full_rect[:width] = 300
full_rect[:height] = 300
XCB.xcb_poly_fill_rectangle(conn, pixmap_id, gc_bg, 1, full_rect)

# Рисование чёрного прямоугольника
rect = XCB::Rectangle.new
rect[:x] = 50
rect[:y] = 50
rect[:width] = 200
rect[:height] = 200
XCB.xcb_poly_fill_rectangle(conn, pixmap_id, gc_fg, 1, rect)

puts "✅ Пиксмап нарисован"

# Цикл событий
puts "🎯 Ожидание событий. Нажмите любую клавишу для выхода"

loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  event_type = event.read_uint8 & ~0x80
  
  case event_type
  when XCB::XCB_EXPOSE
    puts "📋 EXPOSE - копирую пиксмап"
    XCB.xcb_copy_area(conn, pixmap_id, window_id, gc_fg, 0, 0, 0, 0, 300, 300)
    XCB.xcb_flush(conn)
    
  when XCB::XCB_KEY_PRESS
    puts "⌨️  KEY_PRESS - выход"
    break
  end
end

# Очистка
XCB.xcb_free_pixmap(conn, pixmap_id)
XCB.xcb_free_gc(conn, gc_fg)
XCB.xcb_free_gc(conn, gc_bg)
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_disconnect(conn)

puts "✅ Ресурсы освобождены"