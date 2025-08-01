#!/usr/bin/env ruby
require_relative '../lib/xcb'

def test_colors(conn, screen, window)
  puts "🎨 Тестирую цвета..."
  
  # Создание колормапа
  colormap = XCB.xcb_generate_id(conn)
  XCB.xcb_create_colormap(conn, 0, colormap, window, screen[:root_visual])
  
  # Выделение красного цвета
  color_cookie = XCB.xcb_alloc_color(conn, colormap, 65535, 0, 0)
  color_reply = XCB.xcb_alloc_color_reply(conn, color_cookie, nil)
  
  if !color_reply.null?
    puts "✅ Красный цвет выделен"
# memory cleanup
  else
    puts "❌ Ошибка выделения цвета"
  end
  
  XCB.xcb_free_colormap(conn, colormap)
end

def test_fonts(conn)
  puts "🔤 Тестирую шрифты..."
  
  font = XCB.xcb_generate_id(conn)
  XCB.xcb_open_font(conn, font, 5, "fixed")
  XCB.xcb_flush(conn)
  
  # Запрос информации о шрифте
  font_cookie = XCB.xcb_query_font(conn, font)
  font_reply = XCB.xcb_query_font_reply(conn, font_cookie, nil)
  
  if !font_reply.null?
    puts "✅ Шрифт загружен"
# memory cleanup
  else
    puts "❌ Ошибка загрузки шрифта"
  end
  
  XCB.xcb_close_font(conn, font)
end

def test_cursor(conn, screen, window)
  puts "🖱️ Тестирую курсор..."
  
  # Создание пиксмапов для курсора
  cursor_pixmap = XCB.xcb_generate_id(conn)
  mask_pixmap = XCB.xcb_generate_id(conn)
  
  XCB.xcb_create_pixmap(conn, 1, cursor_pixmap, window, 16, 16)
  XCB.xcb_create_pixmap(conn, 1, mask_pixmap, window, 16, 16)
  
  cursor = XCB.xcb_generate_id(conn)
  XCB.xcb_create_cursor(conn, cursor, cursor_pixmap, mask_pixmap,
                        0, 0, 0, 65535, 65535, 65535, 65535)
  
  puts "✅ Курсор создан: #{cursor}"
  
  XCB.xcb_free_cursor(conn, cursor)
  XCB.xcb_free_pixmap(conn, cursor_pixmap)
  XCB.xcb_free_pixmap(conn, mask_pixmap)
end

def test_grab_input(conn, window)
  puts "⌨️ Тестирую захват ввода..."
  
  # Захват указателя
  grab_cookie = XCB.xcb_grab_pointer(conn, 0, window,
    XCB::XCB_EVENT_MASK_BUTTON_PRESS, 0, 0, 0, 0, 0, 0)
  
  grab_reply = XCB.xcb_grab_pointer_reply(conn, grab_cookie, nil)
  if !grab_reply.null?
    puts "✅ Указатель захвачен"
# memory cleanup
    XCB.xcb_ungrab_pointer(conn)
  end
  
  # Запрос позиции указателя
  pointer_cookie = XCB.xcb_query_pointer(conn, window)
  pointer_reply = XCB.xcb_query_pointer_reply(conn, pointer_cookie, nil)
  
  if !pointer_reply.null?
    puts "✅ Позиция указателя получена"
# memory cleanup
  end
end

def test_properties(conn, window)
  puts "🏷️ Тестирую свойства..."
  
  # Интернирование атома
  atom_cookie = XCB.xcb_intern_atom(conn, 0, 8, "WM_CLASS")
  puts "✅ Атом WM_CLASS запрошен"
  
  # Установка свойства (используем стандартный WM_CLASS atom)
  class_name = "TestApp\0TestClass\0"
  XCB.xcb_change_property(conn, 0, window, 67, # WM_CLASS стандартный atom
                         31, 8, class_name.length, class_name) # XCB_ATOM_STRING = 31
  
  puts "✅ Свойство установлено"
end

def test_extensions(conn)
  puts "🔌 Тестирую расширения..."
  
  # Запрос расширения BIG-REQUESTS
  ext_cookie = XCB.xcb_query_extension(conn, 12, "BIG-REQUESTS")
  puts "✅ Расширение BIG-REQUESTS запрошено"
  
  # Список всех расширений
  list_cookie = XCB.xcb_list_extensions(conn)
  puts "✅ Список расширений запрошен"
end

def test_drawing_functions(conn, screen, window)
  puts "🎨 Тестирую функции рисования..."
  
  # Создание GC
  gc = XCB.xcb_generate_id(conn)
  values = FFI::MemoryPointer.new(:uint32, 1)
  values.write(:uint32, screen[:black_pixel])
  XCB.xcb_create_gc(conn, gc, window, XCB::XCB_GC_FOREGROUND, values)
  
  # Очистка области
  XCB.xcb_clear_area(conn, 0, window, 0, 0, 300, 200)
  
  # Рисование точек
  points = FFI::MemoryPointer.new(:int16, 4)
  points[0].write(:int16, 10)
  points[1].write(:int16, 10)
  points[2].write(:int16, 20)
  points[3].write(:int16, 20)
  XCB.xcb_poly_point(conn, 0, window, gc, 2, points)
  
  # Рисование линий
  XCB.xcb_poly_line(conn, 0, window, gc, 2, points)
  
  # Рисование прямоугольника
  rect = XCB::Rectangle.new
  rect[:x] = 50
  rect[:y] = 50
  rect[:width] = 100
  rect[:height] = 80
  XCB.xcb_poly_rectangle(conn, window, gc, 1, rect)
  
  XCB.xcb_flush(conn)
  puts "✅ Функции рисования протестированы"
  
  XCB.xcb_free_gc(conn, gc)
end

# Основной тест
puts "=== Комплексный тест Ruby XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

# Получение экрана
setup = XCB.xcb_get_setup(conn)
screen_iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(screen_iter[:data])

puts "✅ Подключен к экрану: #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]}"

# Создание окна
values = FFI::MemoryPointer.new(:uint32, 1)
values.write(:uint32, XCB::XCB_EVENT_MASK_EXPOSURE)

window = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window, screen[:root],
                      100, 100, 300, 200, 1, XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen[:root_visual], XCB::XCB_CW_EVENT_MASK, values)

XCB.xcb_map_window(conn, window)
XCB.xcb_flush(conn)

# Выполнение всех тестов
test_colors(conn, screen, window)
test_fonts(conn)
test_cursor(conn, screen, window)
test_grab_input(conn, window)
test_properties(conn, window)
test_extensions(conn)
test_drawing_functions(conn, screen, window)

puts "\n🎯 Комплексный Ruby тест завершен!"
puts "Нажмите Enter для закрытия..."

gets

# Очистка
XCB.xcb_destroy_window(conn, window)
XCB.xcb_disconnect(conn)

puts "✅ Завершено"