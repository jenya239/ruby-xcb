# Промпт для отладки XCB пиксмапа в Ruby FFI

## Проблема
Ruby FFI версия показывает белое окно вместо черного прямоугольника на белом фоне. C версия работает корректно.

## Рабочий C код
```c
#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    xcb_connection_t *connection;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_pixmap_t pixmap;
    xcb_gcontext_t gc;

    connection = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(connection)) {
        printf("Ошибка подключения\n");
        return 1;
    }

    screen = xcb_setup_roots_iterator(xcb_get_setup(connection)).data;

    uint32_t mask = XCB_CW_EVENT_MASK;
    uint32_t values[] = { XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS };

    window = xcb_generate_id(connection);
    xcb_create_window(connection,
                      XCB_COPY_FROM_PARENT,
                      window,
                      screen->root,
                      200, 200, 300, 300,
                      1,
                      XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual,
                      mask, values);

    xcb_map_window(connection, window);
    xcb_flush(connection);

    pixmap = xcb_generate_id(connection);
    xcb_create_pixmap(connection, screen->root_depth, pixmap, window, 200, 200);

    gc = xcb_generate_id(connection);
    uint32_t gc_values[] = { screen->black_pixel };
    xcb_create_gc(connection, gc, pixmap, XCB_GC_FOREGROUND, gc_values);

    xcb_rectangle_t rect = { 10, 10, 180, 180 };
    xcb_poly_rectangle(connection, pixmap, gc, 1, &rect);

    xcb_generic_event_t *event;
    while ((event = xcb_wait_for_event(connection))) {
        switch (event->response_type & ~0x80) {
            case XCB_EXPOSE:
                xcb_copy_area(connection, pixmap, window, gc, 0, 0, 0, 0, 200, 200);
                xcb_flush(connection);
                break;
            case XCB_KEY_PRESS:
                free(event);
                goto done;
        }
        free(event);
    }

done:
    xcb_free_pixmap(connection, pixmap);
    xcb_free_gc(connection, gc);
    xcb_destroy_window(connection, window);
    xcb_flush(connection);
    xcb_disconnect(connection);
    return 0;
}
```

## Ключевые отличия от предыдущих попыток

1. **Ожидание события EXPOSE**: Копирование пиксмапа происходит только после получения события `XCB_EXPOSE`
2. **Правильная маска событий**: `XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS`
3. **Использование `screen->root_depth`**: Вместо хардкода 24
4. **Один GC**: Используется один GC для рисования в пиксмап и копирования в окно
5. **Правильные координаты**: `xcb_copy_area(connection, pixmap, window, gc, 0, 0, 0, 0, 200, 200)`

## Задача
Создать Ruby FFI версию, которая точно повторяет логику C кода:
- Ждать событие `XCB_EXPOSE`
- Использовать `screen->root_depth` для создания пиксмапа
- Использовать один GC для всех операций
- Копировать пиксмап только после получения события экспоза

## FFI структуры
Нужно убедиться, что `xcb_rectangle_t` правильно определен:
```ruby
class Rectangle < FFI::Struct
  layout :x, :int16,
         :y, :int16,
         :width, :uint16,
         :height, :uint16
end
```

## Константы
Проверить наличие всех необходимых констант:
- `XCB_GC_FOREGROUND`
- `XCB_EVENT_MASK_EXPOSURE`
- `XCB_EVENT_MASK_KEY_PRESS`
- `XCB_EXPOSE`
- `XCB_KEY_PRESS` 