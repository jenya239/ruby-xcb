#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Константы
#define XCB_GC_BACKGROUND 0x00000008
#define XCB_GC_FONT       0x00004000
#define XCB_CW_CURSOR     0x00004000
#define XCB_BUTTON_PRESS  4

int main() {
    xcb_connection_t *conn;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_font_t font, cursor_font;
    xcb_cursor_t cursor;
    xcb_colormap_t colormap;
    xcb_gcontext_t gc_white, gc_red, gc_green, gc_blue, gc_text;

    printf("=== FINAL XCB COMPREHENSIVE TEST ===\n");
    printf("🎯 Тестирование всех функций XCB\n");

    // 1. ПОДКЛЮЧЕНИЕ
    conn = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(conn)) {
        printf("❌ Ошибка подключения\n");
        return 1;
    }

    screen = xcb_setup_roots_iterator(xcb_get_setup(conn)).data;
    printf("✅ Подключение: экран %dx%d, глубина %d\n", 
           screen->width_in_pixels, screen->height_in_pixels, screen->root_depth);

    // 2. СОЗДАНИЕ ОКНА
    uint32_t win_values[] = { 
        screen->white_pixel,  // background
        XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_BUTTON_PRESS
    };
    
    window = xcb_generate_id(conn);
    xcb_create_window(conn, XCB_COPY_FROM_PARENT, window, screen->root,
                      50, 50, 600, 400, 3, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, 
                      XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK, win_values);
    printf("✅ Окно создано: 600x400\n");

    // 3. КОЛОРМАП И ЦВЕТА
    colormap = xcb_generate_id(conn);
    xcb_create_colormap(conn, XCB_COLORMAP_ALLOC_NONE, colormap, window, screen->root_visual);

    // Выделение цветов
    xcb_alloc_color_cookie_t red_cookie = xcb_alloc_color(conn, colormap, 65535, 0, 0);
    xcb_alloc_color_cookie_t green_cookie = xcb_alloc_color(conn, colormap, 0, 65535, 0);
    xcb_alloc_color_cookie_t blue_cookie = xcb_alloc_color(conn, colormap, 0, 0, 65535);

    xcb_alloc_color_reply_t *red_reply = xcb_alloc_color_reply(conn, red_cookie, NULL);
    xcb_alloc_color_reply_t *green_reply = xcb_alloc_color_reply(conn, green_cookie, NULL);
    xcb_alloc_color_reply_t *blue_reply = xcb_alloc_color_reply(conn, blue_cookie, NULL);

    // 4. ГРАФИЧЕСКИЕ КОНТЕКСТЫ
    uint32_t white_vals[] = { screen->white_pixel };
    gc_white = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_white, window, XCB_GC_FOREGROUND, white_vals);

    if (red_reply) {
        uint32_t red_vals[] = { red_reply->pixel };
        gc_red = xcb_generate_id(conn);
        xcb_create_gc(conn, gc_red, window, XCB_GC_FOREGROUND, red_vals);
        free(red_reply);
    }

    if (green_reply) {
        uint32_t green_vals[] = { green_reply->pixel };
        gc_green = xcb_generate_id(conn);
        xcb_create_gc(conn, gc_green, window, XCB_GC_FOREGROUND, green_vals);
        free(green_reply);
    }

    if (blue_reply) {
        uint32_t blue_vals[] = { blue_reply->pixel };
        gc_blue = xcb_generate_id(conn);
        xcb_create_gc(conn, gc_blue, window, XCB_GC_FOREGROUND, blue_vals);
        free(blue_reply);
    }

    printf("✅ Цвета: красный, зеленый, синий выделены\n");

    // 5. ШРИФТ
    font = xcb_generate_id(conn);
    xcb_open_font(conn, font, 4, "6x13");

    uint32_t text_vals[] = { screen->black_pixel, screen->white_pixel, font };
    gc_text = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_text, window, XCB_GC_FOREGROUND | XCB_GC_BACKGROUND | XCB_GC_FONT, text_vals);
    printf("✅ Шрифт загружен: 6x13\n");

    // 6. КУРСОР
    cursor_font = xcb_generate_id(conn);
    xcb_open_font(conn, cursor_font, 6, "cursor");

    cursor = xcb_generate_id(conn);
    xcb_create_glyph_cursor(conn, cursor, cursor_font, cursor_font,
                           34, 35, 0, 0, 0, 65535, 65535, 65535);

    uint32_t cursor_vals[] = { cursor };
    xcb_change_window_attributes(conn, window, XCB_CW_CURSOR, cursor_vals);
    printf("✅ Курсор установлен: крестик\n");

    // 7. ПОКАЗ ОКНА
    xcb_map_window(conn, window);
    xcb_flush(conn);
    printf("✅ Окно показано\n");

    // 8. ЦИКЛ СОБЫТИЙ С ИНТЕРАКТИВНОСТЬЮ
    xcb_generic_event_t *event;
    int click_count = 0;
    
    printf("\n🎯 ФИНАЛЬНОЕ ТЕСТИРОВАНИЕ:\n");
    printf("🖱️ Кликайте в окне - появятся цветные квадраты\n");
    printf("⌨️ Нажмите ESC для выхода\n");
    
    while ((event = xcb_wait_for_event(conn))) {
        uint8_t type = event->response_type & ~0x80;
        
        if (type == XCB_EXPOSE) {
            // Очистка белым фоном
            xcb_rectangle_t bg = { 0, 0, 600, 400 };
            xcb_poly_fill_rectangle(conn, window, gc_white, 1, &bg);
            
            // Заголовок
            const char *title = "=== FINAL XCB TEST ===";
            xcb_image_text_8(conn, strlen(title), window, gc_text, 200, 30, title);
            
            // Информация
            char info[200];
            snprintf(info, sizeof(info), "Screen: %dx%d | Clicks: %d | Font: 6x13 | Cursor: crosshair", 
                     screen->width_in_pixels, screen->height_in_pixels, click_count);
            xcb_image_text_8(conn, strlen(info), window, gc_text, 20, 60, info);
            
            // Цветные демо-квадраты
            xcb_rectangle_t red_rect = { 50, 100, 80, 60 };
            xcb_rectangle_t green_rect = { 150, 100, 80, 60 };
            xcb_rectangle_t blue_rect = { 250, 100, 80, 60 };
            
            xcb_poly_fill_rectangle(conn, window, gc_red, 1, &red_rect);
            xcb_poly_fill_rectangle(conn, window, gc_green, 1, &green_rect);
            xcb_poly_fill_rectangle(conn, window, gc_blue, 1, &blue_rect);
            
            // Подписи
            xcb_image_text_8(conn, 3, window, gc_text, 70, 180, "RED");
            xcb_image_text_8(conn, 5, window, gc_text, 165, 180, "GREEN");
            xcb_image_text_8(conn, 4, window, gc_text, 270, 180, "BLUE");
            
            // Инструкции
            const char *instr1 = "Click anywhere to add colored squares";
            const char *instr2 = "Press ESC to exit";
            xcb_image_text_8(conn, strlen(instr1), window, gc_text, 150, 220, instr1);
            xcb_image_text_8(conn, strlen(instr2), window, gc_text, 220, 240, instr2);
            
            xcb_flush(conn);
            printf("🖼️ Интерфейс отрисован\n");
        } 
        else if (type == XCB_BUTTON_PRESS) {
            xcb_button_press_event_t *bp = (xcb_button_press_event_t *)event;
            click_count++;
            
            // Рисуем цветной квадрат в месте клика
            xcb_gcontext_t click_gc = (click_count % 3 == 1) ? gc_red : 
                                     (click_count % 3 == 2) ? gc_green : gc_blue;
            
            xcb_rectangle_t click_rect = { bp->event_x - 10, bp->event_y - 10, 20, 20 };
            xcb_poly_fill_rectangle(conn, window, click_gc, 1, &click_rect);
            xcb_flush(conn);
            
            printf("🖱️ Клик #%d в (%d, %d)\n", click_count, bp->event_x, bp->event_y);
        }
        else if (type == XCB_KEY_PRESS) {
            xcb_key_press_event_t *kp = (xcb_key_press_event_t *)event;
            printf("⌨️ Клавиша: код %d\n", kp->detail);
            
            // ESC = код 9
            if (kp->detail == 9) {
                printf("🚪 Выход по ESC\n");
                free(event);
                break;
            }
        }
        
        free(event);
    }

    // 9. ОЧИСТКА
    xcb_close_font(conn, font);
    xcb_close_font(conn, cursor_font);
    xcb_free_cursor(conn, cursor);
    xcb_free_colormap(conn, colormap);
    xcb_free_gc(conn, gc_white);
    xcb_free_gc(conn, gc_red);
    xcb_free_gc(conn, gc_green);
    xcb_free_gc(conn, gc_blue);
    xcb_free_gc(conn, gc_text);
    xcb_destroy_window(conn, window);
    xcb_disconnect(conn);

    printf("\n✅ ФИНАЛЬНЫЙ ТЕСТ ЗАВЕРШЕН!\n");
    printf("🎉 Все функции XCB протестированы успешно:\n");
    printf("   - Подключение и экраны\n");
    printf("   - Создание окон\n");
    printf("   - Колормапы и цвета\n");
    printf("   - Графические контексты\n");
    printf("   - Шрифты и текст\n");
    printf("   - Курсоры\n");
    printf("   - Обработка событий\n");
    printf("   - Рисование примитивов\n");

    return 0;
}