#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Простое окно XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

puts "✅ Подключено к экрану: #{screen_ptr.read_int}"

# Создание окна
window_id = XCB.xcb_generate_id(conn)

# Простое создание окна без событий
XCB.xcb_create_window(
  conn, 0, window_id, 1,
  200, 200, 300, 200,  # позиция и размер
  5, 1, 0, 0, nil      # граница, класс, визуал, маска, значения
)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Окно создано и показано!"
puts "📍 Позиция: (200, 200)"
puts "📏 Размер: 300x200"
puts "🔲 Граница: 5px"
puts ""
puts "🎯 Окно должно быть видно на экране!"
puts "Нажмите Enter для закрытия..."

# Ждем пользователя
gets

# Закрытие
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Окно закрыто"