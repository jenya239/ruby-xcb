#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Рабочий пиксмап XCB с событиями ==="

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
black_pixel = screen[:black_pixel]

puts "✅ Подключено к экрану: #{screen_ptr.read_int}"
puts "📊 Root depth: #{root_depth}"
puts "📊 Black pixel: #{black_pixel}"

# Подготовка атрибутов окна
mask = XCB::XCB_CW_EVENT_MASK
values = FFI::MemoryPointer.new(:uint32, 1)
event_mask = XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS
values.write_array_of_uint32([event_mask])

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ ID окна: #{window_id}"

XCB.xcb_create_window(
  conn, XCB::XCB_COPY_FROM_PARENT, window_id, root,
  200, 200, 300, 300, 1,
  XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT, visual,
  mask, values
)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)
puts "✅ Окно показано"

# Создание пиксмапа
pixmap_id = XCB.xcb_generate_id(conn)
puts "✅ ID пиксмапа: #{pixmap_id}"

# Создание пиксмапа с правильной глубиной
XCB.xcb_create_pixmap(conn, root_depth, pixmap_id, window_id, 200, 200)
puts "✅ Создан пиксмап 200x200 с глубиной #{root_depth}"

# Создание графического контекста
gc_id = XCB.xcb_generate_id(conn)
puts "✅ ID GC: #{gc_id}"

# Создание GC с черным цветом
gc_values = FFI::MemoryPointer.new(:uint32, 1)
gc_values.write_array_of_uint32([black_pixel])

XCB.xcb_create_gc(conn, gc_id, pixmap_id, XCB::XCB_GC_FOREGROUND, gc_values)
puts "✅ Создан GC с черным цветом"

# Рисование в пиксмапе
rect = XCB::Rectangle.new
rect[:x] = 10
rect[:y] = 10
rect[:width] = 180
rect[:height] = 180

XCB.xcb_poly_rectangle(conn, pixmap_id, gc_id, 1, rect)
puts "✅ Нарисован черный прямоугольник в пиксмапе"

# Ожидание событий
puts "🎯 Ожидание события EXPOSE..."
puts "💡 Нажмите любую клавишу для выхода"

loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  event_type = event.read_uint8 & ~0x80
  
  case event_type
  when XCB::XCB_EXPOSE
    puts "📋 Получено событие EXPOSE - копирую пиксмап"
    XCB.xcb_copy_area(conn, pixmap_id, window_id, gc_id, 0, 0, 0, 0, 200, 200)
    XCB.xcb_flush(conn)
    puts "✅ Пиксмап скопирован в окно"
    
  when XCB::XCB_KEY_PRESS
    puts "⌨️  Получено событие KEY_PRESS - выход"
    break
  end
  
  # Освобождение памяти события
  # FFI автоматически освобождает память для событий
end

puts "\n🎯 Должен быть виден черный прямоугольник на белом фоне!"

# Очистка
XCB.xcb_free_pixmap(conn, pixmap_id)
XCB.xcb_free_gc(conn, gc_id)
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Ресурсы освобождены" 