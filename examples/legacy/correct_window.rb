#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Правильное окно XCB (как в C) ==="

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

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ ID окна: #{window_id}"

# Создание окна с правильными параметрами как в C
create_cookie = XCB.xcb_create_window(
  conn,           # соединение
  0,              # глубина (CopyFromParent)
  window_id,      # window id
  1,              # parent (root window)
  200, 200,       # позиция x, y
  400, 300,       # размер width, height
  2,              # толщина границы
  1,              # класс InputOutput
  0,              # visual (CopyFromParent)
  0,              # value mask
  nil             # value list
)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Окно создано и показано!"
puts "📍 Позиция: (200, 200)"
puts "📏 Размер: 400x300"
puts "🔲 Граница: 2px"

puts "\n🎯 Окно должно быть видно на экране!"
puts "Нажмите Enter для закрытия..."

gets

# Закрытие
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Окно закрыто" 