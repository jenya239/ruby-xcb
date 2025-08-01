#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>

// Добавляем недостающие константы
#define XCB_CW_CURSOR 0x00004000
#define XCB_BUTTON_PRESS 4

int main() {
    xcb_connection_t *conn;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_pixmap_t cursor_pixmap, mask_pixmap;
    xcb_cursor_t cursor;
    xcb_gcontext_t gc_black, gc_white;

    printf("=== XCB Cursor Test ===\n");

    // Подключение
    conn = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(conn)) {
        printf("❌ Ошибка подключения к X серверу\n");
        return 1;
    }

    screen = xcb_setup_roots_iterator(xcb_get_setup(conn)).data;
    printf("✅ Подключен к экрану: %dx%d\n", 
           screen->width_in_pixels, screen->height_in_pixels);

    // Создание окна
    uint32_t values[] = { XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_BUTTON_PRESS };
    window = xcb_generate_id(conn);
    xcb_create_window(conn, XCB_COPY_FROM_PARENT, window, screen->root,
                      100, 100, 400, 300, 2, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, XCB_CW_EVENT_MASK, values);

    // Создание пиксмапов для курсора (16x16)
    cursor_pixmap = xcb_generate_id(conn);
    mask_pixmap = xcb_generate_id(conn);
    
    xcb_create_pixmap(conn, 1, cursor_pixmap, window, 16, 16);
    xcb_create_pixmap(conn, 1, mask_pixmap, window, 16, 16);
    
    printf("✅ Пиксмапы для курсора созданы: %d, %d\n", cursor_pixmap, mask_pixmap);

    // GC для рисования курсора
    uint32_t black_vals[] = { screen->black_pixel };
    uint32_t white_vals[] = { screen->white_pixel };
    
    gc_black = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_black, cursor_pixmap, XCB_GC_FOREGROUND, black_vals);
    
    gc_white = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_white, cursor_pixmap, XCB_GC_FOREGROUND, white_vals);

    // Рисование простого курсора (крестик)
    // Очистка пиксмапов
    xcb_rectangle_t clear_rect = { 0, 0, 16, 16 };
    xcb_poly_fill_rectangle(conn, cursor_pixmap, gc_white, 1, &clear_rect);
    xcb_poly_fill_rectangle(conn, mask_pixmap, gc_white, 1, &clear_rect);
    
    // Рисование крестика на cursor_pixmap
    xcb_rectangle_t h_line = { 2, 7, 12, 2 };
    xcb_rectangle_t v_line = { 7, 2, 2, 12 };
    xcb_poly_fill_rectangle(conn, cursor_pixmap, gc_black, 1, &h_line);
    xcb_poly_fill_rectangle(conn, cursor_pixmap, gc_black, 1, &v_line);
    
    // Маска (белые области - видимые)
    xcb_rectangle_t mask_h = { 1, 6, 14, 4 };
    xcb_rectangle_t mask_v = { 6, 1, 4, 14 };
    xcb_poly_fill_rectangle(conn, mask_pixmap, gc_black, 1, &mask_h);
    xcb_poly_fill_rectangle(conn, mask_pixmap, gc_black, 1, &mask_v);
    
    xcb_flush(conn);
    printf("✅ Курсор нарисован в пиксмапах\n");

    // Создание курсора
    cursor = xcb_generate_id(conn);
    xcb_create_cursor(conn, cursor, cursor_pixmap, mask_pixmap,
                      0, 0, 0,           // foreground RGB (черный)
                      65535, 65535, 65535, // background RGB (белый)
                      8, 8);             // hotspot (центр)
    
    printf("✅ Курсор создан: %d\n", cursor);

    // GC для фона окна
    xcb_gcontext_t gc_window_bg = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_window_bg, window, XCB_GC_FOREGROUND, white_vals);

    // Показ окна сначала
    xcb_map_window(conn, window);
    xcb_flush(conn);
    
    // Установка курсора для окна после показа
    uint32_t cursor_vals[] = { cursor };
    xcb_configure_window(conn, window, XCB_CW_CURSOR, cursor_vals);
    xcb_flush(conn);
    
    printf("✅ Окно показано с пользовательским курсором\n");

    // Цикл событий
    xcb_generic_event_t *event;
    printf("🎯 Наведите мышь на окно, чтобы увидеть курсор\n");
    printf("🖱️ Нажмите клавишу или кнопку мыши для выхода\n");
    
    while ((event = xcb_wait_for_event(conn))) {
        uint8_t type = event->response_type & ~0x80;
        
        if (type == XCB_EXPOSE) {
            // Очистка окна белым фоном
            xcb_rectangle_t window_bg = { 0, 0, 400, 300 };
            xcb_poly_fill_rectangle(conn, window, gc_window_bg, 1, &window_bg);
            
            // Добавим простой текст для отладки
            printf("🖼️ Окно очищено белым фоном\n");
            printf("🖱️ Наведите мышь на окно - курсор должен измениться на крестик\n");
            xcb_flush(conn);
        } 
        else if (type == XCB_KEY_PRESS || type == XCB_BUTTON_PRESS) {
            printf("⌨️ Получено событие: %s\n", 
                   type == XCB_KEY_PRESS ? "клавиша" : "кнопка мыши");
            free(event);
            break;
        }
        free(event);
    }

    // Очистка
    xcb_free_cursor(conn, cursor);
    xcb_free_pixmap(conn, cursor_pixmap);
    xcb_free_pixmap(conn, mask_pixmap);
    xcb_free_gc(conn, gc_black);
    xcb_free_gc(conn, gc_white);
    xcb_free_gc(conn, gc_window_bg);
    xcb_destroy_window(conn, window);
    xcb_disconnect(conn);

    printf("✅ Тест курсоров завершен\n");
    return 0;
}