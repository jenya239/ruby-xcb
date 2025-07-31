# Pixmap в XCB

## Что такое Pixmap

Pixmap - это область памяти для рисования, которая существует на сервере X11. В отличие от рисования напрямую в окне, pixmap позволяет:

- Рисовать "за кадром" без видимых артефактов
- Сохранять изображения для быстрой перерисовки
- Создавать сложную графику поэтапно

## Основные принципы

### 1. Создание Pixmap
```c
pixmap_id = xcb_generate_id(connection);
xcb_create_pixmap(connection, depth, pixmap_id, drawable, width, height);
```

**Важно:** Используйте `screen->root_depth` для глубины цвета, не фиксированные значения.

### 2. Графические контексты (GC)
Для рисования в pixmap нужен GC:
```c
gc_id = xcb_generate_id(connection);
xcb_create_gc(connection, gc_id, pixmap_id, mask, values);
```

### 3. Рисование в Pixmap
```c
// Заливка фона
xcb_poly_fill_rectangle(connection, pixmap_id, gc_bg, 1, &full_rect);

// Рисование фигур
xcb_poly_fill_rectangle(connection, pixmap_id, gc_fg, 1, &rect);
```

### 4. Копирование в окно
```c
xcb_copy_area(connection, pixmap_id, window_id, gc, 
              src_x, src_y, dst_x, dst_y, width, height);
```

## Пример C

```c
#include <xcb/xcb.h>

int main() {
    xcb_connection_t *connection;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_pixmap_t pixmap;
    xcb_gcontext_t gc_fg, gc_bg;

    // Подключение
    connection = xcb_connect(NULL, NULL);
    screen = xcb_setup_roots_iterator(xcb_get_setup(connection)).data;

    // Создание окна с событиями
    uint32_t win_values[] = { XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS };
    window = xcb_generate_id(connection);
    xcb_create_window(connection, XCB_COPY_FROM_PARENT, window, screen->root,
                      100, 100, 300, 300, 1, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, XCB_CW_EVENT_MASK, win_values);

    // Создание pixmap
    pixmap = xcb_generate_id(connection);
    xcb_create_pixmap(connection, screen->root_depth, pixmap, window, 300, 300);

    // GC для фона и рисования
    uint32_t bg_vals[] = { screen->white_pixel };
    gc_bg = xcb_generate_id(connection);
    xcb_create_gc(connection, gc_bg, pixmap, XCB_GC_FOREGROUND, bg_vals);

    uint32_t fg_vals[] = { screen->black_pixel };
    gc_fg = xcb_generate_id(connection);
    xcb_create_gc(connection, gc_fg, pixmap, XCB_GC_FOREGROUND, fg_vals);

    // Рисование
    xcb_rectangle_t full = { 0, 0, 300, 300 };
    xcb_poly_fill_rectangle(connection, pixmap, gc_bg, 1, &full);

    xcb_rectangle_t rect = { 50, 50, 200, 200 };
    xcb_poly_fill_rectangle(connection, pixmap, gc_fg, 1, &rect);

    xcb_map_window(connection, window);
    xcb_flush(connection);

    // Обработка событий
    xcb_generic_event_t *event;
    while ((event = xcb_wait_for_event(connection))) {
        uint8_t type = event->response_type & ~0x80;
        if (type == XCB_EXPOSE) {
            xcb_copy_area(connection, pixmap, window, gc_fg, 0, 0, 0, 0, 300, 300);
            xcb_flush(connection);
        } else if (type == XCB_KEY_PRESS) {
            free(event);
            break;
        }
        free(event);
    }

    // Очистка
    xcb_free_pixmap(connection, pixmap);
    xcb_free_gc(connection, gc_fg);
    xcb_free_gc(connection, gc_bg);
    xcb_destroy_window(connection, window);
    xcb_disconnect(connection);

    return 0;
}
```

## Пример Ruby

```ruby
#!/usr/bin/env ruby
require_relative '../lib/xcb'

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

setup = XCB.xcb_get_setup(conn)
iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(iter[:data])

root_depth = screen[:root_depth]
white_pixel = screen[:white_pixel]
black_pixel = screen[:black_pixel]

# Создание окна
window_id = XCB.xcb_generate_id(conn)
mask = XCB::XCB_CW_EVENT_MASK
values = FFI::MemoryPointer.new(:uint32, 1)
event_mask = XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS
values.write_array_of_uint32([event_mask])

XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window_id, screen[:root],
                      100, 100, 300, 300, 1, XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen[:root_visual], mask, values)

# Создание pixmap
pixmap_id = XCB.xcb_generate_id(conn)
XCB.xcb_create_pixmap(conn, root_depth, pixmap_id, window_id, 300, 300)

# GC для фона
gc_bg = XCB.xcb_generate_id(conn)
bg_values = FFI::MemoryPointer.new(:uint32, 1)
bg_values.write_array_of_uint32([white_pixel])
XCB.xcb_create_gc(conn, gc_bg, pixmap_id, XCB::XCB_GC_FOREGROUND, bg_values)

# GC для рисования
gc_fg = XCB.xcb_generate_id(conn)
fg_values = FFI::MemoryPointer.new(:uint32, 1)
fg_values.write_array_of_uint32([black_pixel])
XCB.xcb_create_gc(conn, gc_fg, pixmap_id, XCB::XCB_GC_FOREGROUND, fg_values)

# Рисование
full_rect = XCB::Rectangle.new
full_rect[:x] = 0
full_rect[:y] = 0
full_rect[:width] = 300
full_rect[:height] = 300
XCB.xcb_poly_fill_rectangle(conn, pixmap_id, gc_bg, 1, full_rect)

rect = XCB::Rectangle.new
rect[:x] = 50
rect[:y] = 50
rect[:width] = 200
rect[:height] = 200
XCB.xcb_poly_fill_rectangle(conn, pixmap_id, gc_fg, 1, rect)

XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

# Обработка событий
loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  event_type = event.read_uint8 & ~0x80
  
  case event_type
  when XCB::XCB_EXPOSE
    XCB.xcb_copy_area(conn, pixmap_id, window_id, gc_fg, 0, 0, 0, 0, 300, 300)
    XCB.xcb_flush(conn)
  when XCB::XCB_KEY_PRESS
    break
  end
end

# Очистка
XCB.xcb_free_pixmap(conn, pixmap_id)
XCB.xcb_free_gc(conn, gc_fg)
XCB.xcb_free_gc(conn, gc_bg)
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_disconnect(conn)
```

## Частые ошибки

### 1. Неправильная глубина цвета
❌ `xcb_create_pixmap(conn, 24, pixmap, window, w, h)`
✅ `xcb_create_pixmap(conn, screen->root_depth, pixmap, window, w, h)`

### 2. Размер pixmap меньше окна
❌ Pixmap 200x200, окно 300x300 → визуальный мусор
✅ Pixmap должен быть размером с окно или больше

### 3. Отсутствие заливки фона
❌ Рисование только фигур на неинициализированном pixmap
✅ Сначала заливка всего pixmap фоновым цветом

### 4. Неправильная обработка событий
❌ Копирование pixmap только один раз
✅ Копирование при каждом событии EXPOSE

## Рабочие примеры

- **C:** `c_examples/pixmap_test.c`
- **Ruby:** `examples/stable_pixmap.rb`

## Компиляция и запуск

```bash
# C версия
cd c_examples
gcc -o pixmap_test pixmap_test.c -lxcb
./pixmap_test

# Ruby версия
ruby examples/stable_pixmap.rb
```