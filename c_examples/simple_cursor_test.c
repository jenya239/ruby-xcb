#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    xcb_connection_t *conn;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_font_t cursor_font;
    xcb_cursor_t cursor;
    xcb_gcontext_t gc_bg;

    printf("=== XCB Simple Cursor Test ===\n");

    // Подключение
    conn = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(conn)) {
        printf("❌ Ошибка подключения\n");
        return 1;
    }

    screen = xcb_setup_roots_iterator(xcb_get_setup(conn)).data;
    printf("✅ Подключен к экрану: %dx%d\n", screen->width_in_pixels, screen->height_in_pixels);

    // Создание окна
    uint32_t values[] = { 
        screen->white_pixel,  // background
        XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS 
    };
    
    window = xcb_generate_id(conn);
    xcb_create_window(conn, XCB_COPY_FROM_PARENT, window, screen->root,
                      100, 100, 400, 300, 2, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, 
                      XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK, values);

    // Попробуем создать курсор из системного шрифта
    cursor_font = xcb_generate_id(conn);
    xcb_open_font(conn, cursor_font, 6, "cursor");
    
    cursor = xcb_generate_id(conn);
    xcb_create_glyph_cursor(conn, cursor, cursor_font, cursor_font,
                           34, 35,  // crosshair glyph
                           0, 0, 0,      // foreground (black)
                           65535, 65535, 65535); // background (white)
    
    printf("✅ Системный курсор создан: %d\n", cursor);

    // Установка курсора
    uint32_t cursor_vals[] = { cursor };
    xcb_change_window_attributes(conn, window, XCB_CW_CURSOR, cursor_vals);

    // GC для текста
    uint32_t gc_vals[] = { screen->black_pixel };
    gc_bg = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_bg, window, XCB_GC_FOREGROUND, gc_vals);

    // Показ окна
    xcb_map_window(conn, window);
    xcb_flush(conn);
    printf("✅ Окно показано с системным курсором\n");

    // Цикл событий
    xcb_generic_event_t *event;
    printf("🎯 Наведите мышь на окно - курсор должен измениться\n");
    printf("⌨️ Нажмите любую клавишу для выхода\n");
    
    while ((event = xcb_wait_for_event(conn))) {
        uint8_t type = event->response_type & ~0x80;
        
        if (type == XCB_EXPOSE) {
            // Рисуем простые линии для проверки
            xcb_point_t points[] = {
                {50, 50}, {350, 50},   // горизонтальная линия
                {50, 50}, {50, 250},   // вертикальная линия
                {50, 250}, {350, 250}, // нижняя линия
                {350, 50}, {350, 250}  // правая линия
            };
            
            xcb_poly_line(conn, XCB_COORD_MODE_ORIGIN, window, gc_bg, 8, points);
            xcb_flush(conn);
            printf("🖼️ Линии нарисованы, курсор должен быть активен\n");
        } 
        else if (type == XCB_KEY_PRESS) {
            printf("⌨️ Клавиша нажата\n");
            free(event);
            break;
        }
        free(event);
    }

    // Очистка
    xcb_close_font(conn, cursor_font);
    xcb_free_cursor(conn, cursor);
    xcb_free_gc(conn, gc_bg);
    xcb_destroy_window(conn, window);
    xcb_disconnect(conn);

    printf("✅ Простой тест курсоров завершен\n");
    return 0;
}