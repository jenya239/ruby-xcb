#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    xcb_connection_t *connection;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_pixmap_t pixmap;
    xcb_gcontext_t gc_fg, gc_bg;

    connection = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(connection)) {
        fprintf(stderr, "Ошибка подключения к X серверу\n");
        return 1;
    }

    screen = xcb_setup_roots_iterator(xcb_get_setup(connection)).data;

    // Создаём окно с подпиской на события
    uint32_t win_values[] = { XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS };
    window = xcb_generate_id(connection);
    xcb_create_window(connection,
                      XCB_COPY_FROM_PARENT,
                      window,
                      screen->root,
                      100, 100, 300, 300,
                      1,
                      XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual,
                      XCB_CW_EVENT_MASK, win_values);

    xcb_map_window(connection, window);
    xcb_flush(connection);

    // Создаём пиксмап размером с окно
    pixmap = xcb_generate_id(connection);
    xcb_create_pixmap(connection, screen->root_depth, pixmap, window, 300, 300);

    // GC для белого фона
    uint32_t bg_vals[] = { screen->white_pixel };
    gc_bg = xcb_generate_id(connection);
    xcb_create_gc(connection, gc_bg, pixmap, XCB_GC_FOREGROUND, bg_vals);

    // GC для чёрного прямоугольника
    uint32_t fg_vals[] = { screen->black_pixel };
    gc_fg = xcb_generate_id(connection);
    xcb_create_gc(connection, gc_fg, pixmap, XCB_GC_FOREGROUND, fg_vals);

    // Заливаем белым весь пиксмап
    xcb_rectangle_t full = { 0, 0, 300, 300 };
    xcb_poly_fill_rectangle(connection, pixmap, gc_bg, 1, &full);

    // Рисуем чёрный прямоугольник
    xcb_rectangle_t rect = { 50, 50, 200, 200 };
    xcb_poly_fill_rectangle(connection, pixmap, gc_fg, 1, &rect);

    // Цикл событий
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