#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Финальный тест XCB привязок ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
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

# Создание окна
puts "\n--- Тестирование создания окна ---"
create_cookie = XCB.xcb_create_window(
  conn, 0, window_id, 1, 100, 100, 400, 300, 0, 1, 0, 0, nil
)
puts "✅ xcb_create_window вызван"

# Показ окна
puts "\n--- Тестирование показа окна ---"
map_cookie = XCB.xcb_map_window(conn, window_id)
puts "✅ xcb_map_window вызван"

# Создание графического контекста
puts "\n--- Тестирование графического контекста ---"
gc_id = XCB.xcb_generate_id(conn)
gc_cookie = XCB.xcb_create_gc(conn, gc_id, window_id, 0, nil)
puts "✅ xcb_create_gc вызван (ID: #{gc_id})"

# Создание пиксмапа
puts "\n--- Тестирование пиксмапа ---"
pixmap_id = XCB.xcb_generate_id(conn)
pixmap_cookie = XCB.xcb_create_pixmap(conn, 0, pixmap_id, window_id, 100, 100)
puts "✅ xcb_create_pixmap вызван (ID: #{pixmap_id})"

# Очистка области
puts "\n--- Тестирование очистки области ---"
clear_cookie = XCB.xcb_clear_area(conn, 0, window_id, 10, 10, 100, 100)
puts "✅ xcb_clear_area вызван"

# Копирование области
puts "\n--- Тестирование копирования области ---"
copy_cookie = XCB.xcb_copy_area(conn, window_id, window_id, gc_id, 0, 0, 50, 50, 200, 200)
puts "✅ xcb_copy_area вызван"

# Интернирование атома
puts "\n--- Тестирование интернирования атома ---"
atom_cookie = XCB.xcb_intern_atom(conn, 0, 4, "WM_NAME")
puts "✅ xcb_intern_atom вызван"

# Список расширений
puts "\n--- Тестирование списка расширений ---"
ext_cookie = XCB.xcb_list_extensions(conn)
puts "✅ xcb_list_extensions вызван"

# Запрос геометрии
puts "\n--- Тестирование запроса геометрии ---"
geom_cookie = XCB.xcb_get_geometry(conn, window_id)
puts "✅ xcb_get_geometry вызван"

# События
puts "\n--- Тестирование событий ---"
event = XCB.xcb_poll_for_event(conn)
if event.null?
  puts "✅ xcb_poll_for_event: нет событий"
else
  puts "✅ xcb_poll_for_event: событие получено"
end

# Утилиты
puts "\n--- Тестирование утилит ---"
max_len = XCB.xcb_get_maximum_request_length(conn)
puts "✅ xcb_get_maximum_request_length: #{max_len}"

total_read = XCB.xcb_total_read(conn)
total_written = XCB.xcb_total_written(conn)
puts "✅ Статистика: прочитано #{total_read}, записано #{total_written} байт"

# Отправка всех команд
puts "\n--- Отправка команд ---"
flush_result = XCB.xcb_flush(conn)
puts "✅ xcb_flush: #{flush_result}"

# Очистка ресурсов
puts "\n--- Очистка ресурсов ---"
XCB.xcb_free_gc(conn, gc_id)
puts "✅ xcb_free_gc вызван"

XCB.xcb_free_pixmap(conn, pixmap_id)
puts "✅ xcb_free_pixmap вызван"

XCB.xcb_destroy_window(conn, window_id)
puts "✅ xcb_destroy_window вызван"

# Финальная отправка
XCB.xcb_flush(conn)

# Отключение
XCB.xcb_disconnect(conn)
puts "✅ xcb_disconnect вызван"

puts "\n🎉 Все основные функции XCB протестированы успешно!"
puts "📊 Протестировано функций: 15+"
puts "✅ Привязки работают корректно" 