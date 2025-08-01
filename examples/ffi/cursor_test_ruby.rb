#!/usr/bin/env ruby
require_relative '../lib/xcb'

puts "=== Ruby XCB Cursor Test ==="

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

# Создание окна с белым фоном
values = FFI::MemoryPointer.new(:uint32, 2)
values[0].write(:uint32, screen[:white_pixel])  # background
values[1].write(:uint32, XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS)

window = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window, screen[:root],
                      100, 100, 400, 300, 2, XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen[:root_visual], 
                      XCB::XCB_CW_BACK_PIXEL | XCB::XCB_CW_EVENT_MASK, values)

# Создание курсора из системного шрифта
cursor_font = XCB.xcb_generate_id(conn)
XCB.xcb_open_font(conn, cursor_font, 6, "cursor")

cursor = XCB.xcb_generate_id(conn)
XCB.xcb_create_glyph_cursor(conn, cursor, cursor_font, cursor_font,
                           34, 35,  # crosshair glyph
                           0, 0, 0,      # foreground (black)
                           65535, 65535, 65535) # background (white)

puts "✅ Системный курсор создан: #{cursor}"

# Установка курсора
cursor_vals = FFI::MemoryPointer.new(:uint32, 1)
cursor_vals.write(:uint32, cursor)
XCB.xcb_change_window_attributes(conn, window, XCB::XCB_CW_CURSOR, cursor_vals)

# GC для рисования линий
gc_vals = FFI::MemoryPointer.new(:uint32, 1)
gc_vals.write(:uint32, screen[:black_pixel])
gc = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc, window, XCB::XCB_GC_FOREGROUND, gc_vals)

# Показ окна
XCB.xcb_map_window(conn, window)
XCB.xcb_flush(conn)
puts "✅ Окно показано с системным курсором"

# Цикл событий
puts "🎯 Наведите мышь на окно - курсор должен измениться"
puts "⌨️ Нажмите любую клавишу для выхода"

loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  generic_event = XCB::GenericEvent.new(event)
  type = generic_event[:response_type] & ~0x80
  
  if type == XCB::XCB_EXPOSE
    # Рисуем простые линии для проверки (рамку)
    points = []
    
    # Создаем массив точек для рамки
    frame_points = [
      [50, 50], [350, 50],   # верхняя линия
      [50, 50], [50, 250],   # левая линия  
      [50, 250], [350, 250], # нижняя линия
      [350, 50], [350, 250]  # правая линия
    ]
    
    frame_points.each do |point_pair|
      point1 = XCB::Point.new
      point1[:x] = point_pair[0][0]
      point1[:y] = point_pair[0][1]
      
      point2 = XCB::Point.new  
      point2[:x] = point_pair[1][0]
      point2[:y] = point_pair[1][1]
      
      points_array = FFI::MemoryPointer.new(XCB::Point, 2)
      points_array[0].write_bytes(point1.to_ptr.read_bytes(XCB::Point.size))
      points_array[1].write_bytes(point2.to_ptr.read_bytes(XCB::Point.size))
      
      XCB.xcb_poly_line(conn, XCB::XCB_COORD_MODE_ORIGIN, window, gc, 2, points_array)
    end
    
    XCB.xcb_flush(conn)
    puts "🖼️ Линии нарисованы, курсор должен быть активен"
    
  elsif type == XCB::XCB_KEY_PRESS
    puts "⌨️ Клавиша нажата"
    break
  end
end

# Очистка
XCB.xcb_close_font(conn, cursor_font)
XCB.xcb_free_cursor(conn, cursor)
XCB.xcb_free_gc(conn, gc)
XCB.xcb_destroy_window(conn, window)
XCB.xcb_disconnect(conn)

puts "✅ Ruby тест курсоров завершен"