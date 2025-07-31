#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Правильное окно XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

screen_num = screen_ptr.read_int
puts "✅ Подключено к экрану: #{screen_num}"

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ ID окна: #{window_id}"

# Создание окна с правильными атрибутами
create_cookie = XCB.xcb_create_window(
  conn,           # соединение
  0,              # глубина (CopyFromParent)
  window_id,      # window id
  1,              # parent (root window)
  400, 400,       # позиция x, y
  500, 400,       # размер width, height
  0,              # толщина границы
  1,              # класс InputOutput
  0,              # visual (CopyFromParent)
  0,              # value mask
  nil             # value list
)

# Установка имени окна
atom_cookie = XCB.xcb_intern_atom(conn, 0, 8, "WM_NAME")
XCB.xcb_flush(conn)

# Установка заголовка окна
title = "Ruby XCB Window"
XCB.xcb_change_property(conn, 0, window_id, 39, 31, 8, title.length, title)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Окно создано и показано!"
puts "📍 Позиция: (400, 400)"
puts "📏 Размер: 500x400"
puts "🏷️  Заголовок: #{title}"

puts "\n🎯 Ищите окно '#{title}' на экране!"
puts "Нажмите Enter для закрытия..."

gets

# Закрытие
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Окно закрыто" 