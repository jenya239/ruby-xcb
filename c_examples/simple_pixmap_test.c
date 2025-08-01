#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    xcb_connection_t *conn;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_pixmap_t pixmap;
    xcb_gcontext_t gc_fg, gc_bg;

    // Подключение
    conn = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(conn)) {
        printf("❌ Ошибка подключения\n");
        return 1;
    }

    screen = xcb_setup_roots_iterator(xcb_get_setup(conn)).data;
    printf("✅ Подключено к экрану: %dx%d\n", screen->width_in_pixels, screen->height_in_pixels);

    // Окно с событиями
    uint32_t values[] = { XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS };
    window = xcb_generate_id(conn);
    xcb_create_window(conn, XCB_COPY_FROM_PARENT, window, screen->root,
                      50, 50, 250, 200, 1, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, XCB_CW_EVENT_MASK, values);

    xcb_map_window(conn, window);
    xcb_flush(conn);
    printf("✅ Окно создано: %d\n", window);

    // Пиксмап
    pixmap = xcb_generate_id(conn);
    xcb_create_pixmap(conn, screen->root_depth, pixmap, window, 250, 200);

    // GC белый/черный
    uint32_t white[] = { screen->white_pixel };
    uint32_t black[] = { screen->black_pixel };
    
    gc_bg = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_bg, pixmap, XCB_GC_FOREGROUND, white);
    
    gc_fg = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_fg, pixmap, XCB_GC_FOREGROUND, black);

    // Рисование
    xcb_rectangle_t bg = { 0, 0, 250, 200 };
    xcb_poly_fill_rectangle(conn, pixmap, gc_bg, 1, &bg);
    
    xcb_rectangle_t rect = { 25, 25, 200, 150 };
    xcb_poly_fill_rectangle(conn, pixmap, gc_fg, 1, &rect);
    
    printf("✅ Пиксмап готов с прямоугольником\n");

    // События
    xcb_generic_event_t *event;
    printf("🎯 Окно показано. ESC для выхода\n");
    
    while ((event = xcb_wait_for_event(conn))) {
        uint8_t type = event->response_type & ~0x80;
        if (type == XCB_EXPOSE) {
            xcb_copy_area(conn, pixmap, window, gc_fg, 0, 0, 0, 0, 250, 200);
            xcb_flush(conn);
        } else if (type == XCB_KEY_PRESS) {
            free(event);
            break;
        }
        free(event);
    }

    // Очистка
    xcb_free_pixmap(conn, pixmap);
    xcb_free_gc(conn, gc_fg);
    xcb_free_gc(conn, gc_bg);
    xcb_destroy_window(conn, window);
    xcb_disconnect(conn);
    
    printf("✅ Завершено\n");
    return 0;
}