#!/usr/bin/env ruby
require_relative '../lib/xcb'

puts "=== Ruby XCB Pixmap Test ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

# Получение экрана
setup = XCB.xcb_get_setup(conn)
screen_iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(screen_iter[:data])

puts "✅ Подключено к экрану: #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]}"

# Создание окна с событиями
values = FFI::MemoryPointer.new(:uint32, 1)
values.write(:uint32, XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS)

window = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window, screen[:root],
                      50, 50, 250, 200, 1, XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen[:root_visual], XCB::XCB_CW_EVENT_MASK, values)

XCB.xcb_map_window(conn, window)
XCB.xcb_flush(conn)
puts "✅ Окно создано: #{window}"

# Создание пиксмапа
pixmap = XCB.xcb_generate_id(conn)
XCB.xcb_create_pixmap(conn, screen[:root_depth], pixmap, window, 250, 200)

# Графические контексты
white_val = FFI::MemoryPointer.new(:uint32, 1)
white_val.write(:uint32, screen[:white_pixel])
gc_bg = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_bg, pixmap, XCB::XCB_GC_FOREGROUND, white_val)

black_val = FFI::MemoryPointer.new(:uint32, 1)
black_val.write(:uint32, screen[:black_pixel])
gc_fg = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_fg, pixmap, XCB::XCB_GC_FOREGROUND, black_val)

# Рисование на пиксмапе
bg_rect = XCB::Rectangle.new
bg_rect[:x] = 0
bg_rect[:y] = 0
bg_rect[:width] = 250
bg_rect[:height] = 200
XCB.xcb_poly_fill_rectangle(conn, pixmap, gc_bg, 1, bg_rect)

fg_rect = XCB::Rectangle.new
fg_rect[:x] = 25
fg_rect[:y] = 25
fg_rect[:width] = 200
fg_rect[:height] = 150
XCB.xcb_poly_fill_rectangle(conn, pixmap, gc_fg, 1, fg_rect)

puts "✅ Пиксмап готов с прямоугольником"

# Цикл событий
puts "🎯 Окно показано. Нажмите любую клавишу для выхода"

loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  generic_event = XCB::GenericEvent.new(event)
  type = generic_event[:response_type] & ~0x80
  
  if type == XCB::XCB_EXPOSE
    XCB.xcb_copy_area(conn, pixmap, window, gc_fg, 0, 0, 0, 0, 250, 200)
    XCB.xcb_flush(conn)
  elsif type == XCB::XCB_KEY_PRESS
    FFI::MemoryPointer.from_string("").autorelease = false
    break
  end
  
  FFI::MemoryPointer.from_string("").autorelease = false
end

# Очистка
XCB.xcb_free_pixmap(conn, pixmap)
XCB.xcb_free_gc(conn, gc_fg)
XCB.xcb_free_gc(conn, gc_bg)
XCB.xcb_destroy_window(conn, window)
XCB.xcb_disconnect(conn)

puts "✅ Завершено"