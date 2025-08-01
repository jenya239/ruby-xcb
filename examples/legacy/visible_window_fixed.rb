#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Исправленное видимое окно XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

screen_num = screen_ptr.read_int
puts "✅ Подключено к экрану: #{screen_num}"

# Получение setup для определения root window
setup = XCB.xcb_get_setup(conn)
if setup.null?
  puts "❌ Не удалось получить setup"
  XCB.xcb_disconnect(conn)
  exit 1
end

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ ID окна: #{window_id}"

# Создание окна с правильными атрибутами
create_cookie = XCB.xcb_create_window(
  conn,           # соединение
  24,             # глубина цвета (24 бит)
  window_id,      # window id
  1,              # parent (root window)
  300, 300,       # позиция x, y
  400, 300,       # размер width, height
  10,             # толщина границы
  1,              # класс InputOutput
  0,              # visual (CopyFromParent)
  0,              # value mask (без дополнительных атрибутов)
  nil             # value list
)

# Проверка ошибок создания
error = XCB.xcb_request_check(conn, create_cookie)
if !error.null?
  puts "❌ Ошибка создания окна"
  XCB.xcb_disconnect(conn)
  exit 1
end

puts "✅ Окно создано успешно"

# Показ окна
map_cookie = XCB.xcb_map_window(conn, window_id)
error = XCB.xcb_request_check(conn, map_cookie)
if !error.null?
  puts "❌ Ошибка показа окна"
else
  puts "✅ Окно показано"
end

# Отправка команд
XCB.xcb_flush(conn)

puts "\n🎯 Окно должно быть видно на экране!"
puts "📍 Позиция: (300, 300)"
puts "📏 Размер: 400x300"
puts "🔲 Граница: 10px"
puts "🎨 Глубина: 24 бита"

# Создание графического контекста для рисования
gc_id = XCB.xcb_generate_id(conn)
gc_cookie = XCB.xcb_create_gc(conn, gc_id, window_id, 0, nil)
error = XCB.xcb_request_check(conn, gc_cookie)
if error.null?
  puts "✅ Графический контекст создан"
  
  # Очистка окна (сделает его белым)
  clear_cookie = XCB.xcb_clear_area(conn, 0, window_id, 0, 0, 400, 300)
  XCB.xcb_flush(conn)
  puts "✅ Окно очищено (белый фон)"
end

puts "\nНажмите Enter для закрытия..."
gets

# Очистка
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Окно закрыто" 