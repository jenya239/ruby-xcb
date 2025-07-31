#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Исправленное окно XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

screen_num = screen_ptr.read_int
puts "✅ Подключено к экрану: #{screen_num}"

# Получение setup и screen
setup = XCB.xcb_get_setup(conn)
if setup.null?
  puts "❌ Не удалось получить setup"
  XCB.xcb_disconnect(conn)
  exit 1
end

# Получение screen через iterator
iter = XCB.xcb_setup_roots_iterator(setup)
screen_data = iter[:data]
screen = XCB::Screen.new(screen_data)

root = screen[:root]
visual = screen[:root_visual]
white_pixel = screen[:white_pixel]

puts "✅ Root window: #{root}"
puts "✅ Root visual: #{visual}"
puts "✅ White pixel: #{white_pixel}"

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ ID окна: #{window_id}"

# Подготовка атрибутов окна
value_mask = XCB::XCB_CW_BACK_PIXEL | XCB::XCB_CW_EVENT_MASK
value_list = FFI::MemoryPointer.new(:uint32, 2)
value_list.write_array_of_uint32([white_pixel, XCB::XCB_EVENT_MASK_EXPOSURE])

# Создание окна с правильными параметрами
create_cookie = XCB.xcb_create_window(
  conn,                    # соединение
  XCB::XCB_COPY_FROM_PARENT, # глубина (CopyFromParent)
  window_id,               # window id
  root,                    # parent (root window)
  100, 100,               # позиция x, y
  400, 300,               # размер width, height
  2,                      # толщина границы
  XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT, # класс InputOutput
  visual,                 # visual (root visual)
  value_mask,             # value mask
  value_list              # value list
)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Окно создано и показано!"
puts "📍 Позиция: (100, 100)"
puts "📏 Размер: 400x300"
puts "🔲 Граница: 2px"
puts "🎨 Фон: белый"

puts "\n🎯 Окно должно быть видно на экране!"
puts "Нажмите Enter для закрытия..."

gets

# Закрытие
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Окно закрыто" 