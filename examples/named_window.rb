#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Создание именованного окна XCB ==="

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
puts "✅ ID окна: #{window_id}"

# Создание большого заметного окна
create_cookie = XCB.xcb_create_window(
  conn, 0, window_id, 1,
  50, 50,        # позиция
  500, 400,      # размер (больше)
  10,            # толстая граница
  1, 0, 0, nil
)

# Показ окна
XCB.xcb_map_window(conn, window_id)

# Установка имени окна
atom_cookie = XCB.xcb_intern_atom(conn, 0, 8, "WM_NAME")
XCB.xcb_flush(conn)

# Установка заголовка
title = "XCB Ruby Window Test"
XCB.xcb_change_property(conn, 0, window_id, 39, 31, 8, title.length, title)

XCB.xcb_flush(conn)

puts "✅ Окно создано: #{title}"
puts "📍 Позиция: (50, 50)"
puts "📏 Размер: 500x400"
puts "🔲 Граница: 10px"

puts "\n🎯 Ищите окно '#{title}' на экране!"
puts "Нажмите Enter для закрытия..."

# Небольшая пауза для отображения
sleep(1)

gets

# Закрытие
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Окно закрыто"