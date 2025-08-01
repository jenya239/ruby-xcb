#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Окно с атомами и свойствами XCB ==="

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
  500, 500, 400, 300, 2,
  XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT, visual,
  value_mask, value_list
)

# Интернирование атомов
wm_name_atom = XCB.xcb_intern_atom(conn, 0, 8, "WM_NAME")
wm_class_atom = XCB.xcb_intern_atom(conn, 0, 12, "WM_CLASS")
XCB.xcb_flush(conn)
puts "✅ Атомы интернированы"

# Установка имени окна
title = "Ruby XCB Property Test"
XCB.xcb_change_property(conn, 0, window_id, 39, 31, 8, title.length, title)
puts "✅ Установлено имя окна: #{title}"

# Установка класса окна
class_name = "RubyXCB\0TestWindow"
XCB.xcb_change_property(conn, 0, window_id, 39, 32, 8, class_name.length, class_name)
puts "✅ Установлен класс окна"

# Установка пользовательского свойства
custom_prop = "CustomValue"
XCB.xcb_change_property(conn, 0, window_id, 39, 33, 8, custom_prop.length, custom_prop)
puts "✅ Установлено пользовательское свойство"

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Окно создано с свойствами!"
puts "🏷️  Имя: #{title}"
puts "📋 Класс: TestWindow"

puts "\n🎯 Проверьте свойства окна через xprop!"
puts "Нажмите Enter для закрытия..."

gets

# Очистка
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Ресурсы освобождены" 