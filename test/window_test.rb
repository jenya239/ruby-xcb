#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Тест окна XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

screen = screen_ptr.read_int
puts "✅ Подключено к экрану: #{screen}"

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ ID окна: #{window_id}"

create_cookie = XCB.xcb_create_window(
  conn, 0, window_id, 1, 100, 100, 400, 300, 0, 1, 0, 0, nil
)

if XCB.xcb_request_check(conn, create_cookie).null?
  puts "✅ Окно создано успешно"
else
  puts "❌ Ошибка создания окна"
  XCB.xcb_disconnect(conn)
  exit 1
end

# Показ окна
map_cookie = XCB.xcb_map_window(conn, window_id)
if XCB.xcb_request_check(conn, map_cookie).null?
  puts "✅ Окно показано успешно"
else
  puts "❌ Ошибка показа окна"
end

# Отправка команд
XCB.xcb_flush(conn)
puts "✅ Команды отправлены"

# Ожидание
puts "Окно должно появиться на экране. Нажмите Enter для продолжения..."
gets

# Скрытие окна
unmap_cookie = XCB.xcb_unmap_window(conn, window_id)
if XCB.xcb_request_check(conn, unmap_cookie).null?
  puts "✅ Окно скрыто успешно"
else
  puts "❌ Ошибка скрытия окна"
end

# Уничтожение окна
destroy_cookie = XCB.xcb_destroy_window(conn, window_id)
if XCB.xcb_request_check(conn, destroy_cookie).null?
  puts "✅ Окно уничтожено успешно"
else
  puts "❌ Ошибка уничтожения окна"
end

XCB.xcb_flush(conn)

# Отключение
XCB.xcb_disconnect(conn)
puts "✅ Отключено от X сервера"

puts "\n🎉 Тест окна завершен успешно!" 