#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Простой тест XCB привязок ==="

# Подключение к X серверу
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null?
  puts "❌ Ошибка подключения к X серверу"
  exit 1
end

if XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка соединения с X сервером"
  exit 1
end

screen = screen_ptr.read_int
puts "✅ Подключено к экрану: #{screen}"

# Получение setup информации
setup = XCB.xcb_get_setup(conn)
if setup.null?
  puts "❌ Не удалось получить setup информацию"
  XCB.xcb_disconnect(conn)
  exit 1
end
puts "✅ Setup информация получена"

# Генерация ID
window_id = XCB.xcb_generate_id(conn)
puts "✅ Сгенерирован ID окна: #{window_id}"

# Получение статистики
total_read = XCB.xcb_total_read(conn)
total_written = XCB.xcb_total_written(conn)
puts "✅ Статистика соединения: прочитано #{total_read}, записано #{total_written} байт"

# Отправка буфера
flush_result = XCB.xcb_flush(conn)
puts "✅ Буфер отправлен (результат: #{flush_result})"

# Отключение
XCB.xcb_disconnect(conn)
puts "✅ Отключено от X сервера"

puts "\n🎉 Все базовые функции XCB работают корректно!" 