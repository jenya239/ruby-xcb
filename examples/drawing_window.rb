#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Окно с рисованием XCB ==="

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
  300, 300, 600, 400, 2,
  XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT, visual,
  value_mask, value_list
)

# Создание графического контекста
gc_id = XCB.xcb_generate_id(conn)
puts "✅ ID графического контекста: #{gc_id}"

# Создание GC с черным цветом
gc_mask = 0x00000004  # GCForeground
gc_values = FFI::MemoryPointer.new(:uint32, 1)
gc_values.write_array_of_uint32([black_pixel])

XCB.xcb_create_gc(conn, gc_id, window_id, gc_mask, gc_values)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Окно создано с графическим контекстом!"
puts "🎨 Рисуем фигуры..."

# Очистка окна (белый фон)
XCB.xcb_clear_area(conn, 0, window_id, 0, 0, 600, 400)
XCB.xcb_flush(conn)
puts "✅ Окно очищено"

# Рисование прямоугольника
rect_data = FFI::MemoryPointer.new(:int16, 4)
rect_data.write_array_of_int16([50, 50, 200, 100])
XCB.xcb_poly_rectangle(conn, window_id, gc_id, 1, rect_data)
XCB.xcb_flush(conn)
puts "✅ Нарисован прямоугольник"

# Рисование линии
line_data = FFI::MemoryPointer.new(:int16, 4)
line_data.write_array_of_int16([100, 200, 300, 250])
XCB.xcb_poly_line(conn, 0, window_id, gc_id, 2, line_data)
XCB.xcb_flush(conn)
puts "✅ Нарисована линия"

# Рисование точек
point_data = FFI::MemoryPointer.new(:int16, 6)
point_data.write_array_of_int16([400, 100, 450, 150, 500, 200])
XCB.xcb_poly_point(conn, 0, window_id, gc_id, 3, point_data)
XCB.xcb_flush(conn)
puts "✅ Нарисованы точки"

puts "\n🎯 Смотрите нарисованные фигуры в окне!"
puts "Нажмите Enter для закрытия..."

gets

# Очистка
XCB.xcb_free_gc(conn, gc_id)
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Ресурсы освобождены" 