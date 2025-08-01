#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Окно с пиксмапами XCB ==="

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
white_pixel = screen[:white_pixel]
black_pixel = screen[:black_pixel]

puts "✅ Подключено к экрану: #{screen_ptr.read_int}"

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ ID окна: #{window_id}"

# Подготовка атрибутов окна
value_mask = XCB::XCB_CW_BACK_PIXEL | XCB::XCB_CW_EVENT_MASK
value_list = FFI::MemoryPointer.new(:uint32, 2)
event_mask = XCB::XCB_EVENT_MASK_EXPOSURE
value_list.write_array_of_uint32([white_pixel, event_mask])

# Создание окна
XCB.xcb_create_window(
  conn, XCB::XCB_COPY_FROM_PARENT, window_id, root,
  400, 400, 500, 400, 2,
  XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT, visual,
  value_mask, value_list
)

# Создание пиксмапа
pixmap_id = XCB.xcb_generate_id(conn)
puts "✅ ID пиксмапа: #{pixmap_id}"

# Создание пиксмапа 200x200
XCB.xcb_create_pixmap(conn, 24, pixmap_id, window_id, 200, 200)
puts "✅ Создан пиксмап 200x200"

# Создание графического контекста для пиксмапа
gc_id = XCB.xcb_generate_id(conn)
puts "✅ ID графического контекста: #{gc_id}"

# Создание GC с черным цветом
gc_mask = 0x00000004  # GCForeground
gc_values = FFI::MemoryPointer.new(:uint32, 1)
gc_values.write_array_of_uint32([black_pixel])

XCB.xcb_create_gc(conn, gc_id, pixmap_id, gc_mask, gc_values)

# Рисование в пиксмапе
XCB.xcb_clear_area(conn, 0, pixmap_id, 0, 0, 200, 200)
rect_data = FFI::MemoryPointer.new(:int16, 4)
rect_data.write_array_of_int16([20, 20, 160, 160])
XCB.xcb_poly_rectangle(conn, pixmap_id, gc_id, 1, rect_data)
XCB.xcb_flush(conn)
puts "✅ Нарисован прямоугольник в пиксмапе"

# Копирование пиксмапа в окно
XCB.xcb_copy_area(conn, pixmap_id, window_id, gc_id, 0, 0, 50, 50, 200, 200)
XCB.xcb_flush(conn)
puts "✅ Пиксмап скопирован в окно"

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Окно создано с пиксмапом!"
puts "🎨 Пиксмап отображается в окне"

puts "\n🎯 Смотрите пиксмап в окне!"
puts "Нажмите Enter для закрытия..."

gets

# Очистка
XCB.xcb_free_pixmap(conn, pixmap_id)
XCB.xcb_free_gc(conn, gc_id)
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Ресурсы освобождены" 