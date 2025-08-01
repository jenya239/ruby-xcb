#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Добавляем недостающие константы
#define XCB_GC_BACKGROUND 0x00000008
#define XCB_GC_FONT       0x00004000

int main() {
    xcb_connection_t *conn;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_font_t font;
    xcb_gcontext_t gc_text, gc_bg;

    printf("=== XCB Font Test ===\n");

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
    uint32_t values[] = { XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS };
    window = xcb_generate_id(conn);
    xcb_create_window(conn, XCB_COPY_FROM_PARENT, window, screen->root,
                      100, 100, 500, 300, 2, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, XCB_CW_EVENT_MASK, values);

    // Загрузка шрифта (попробуем разные шрифты)
    font = xcb_generate_id(conn);
    xcb_open_font(conn, font, 4, "6x13");  // Попробуем другой шрифт
    xcb_flush(conn);
    printf("✅ Шрифт '6x13' загружен: %d\n", font);

    // Запрос информации о шрифте
    xcb_query_font_cookie_t font_cookie = xcb_query_font(conn, font);
    xcb_query_font_reply_t *font_reply = xcb_query_font_reply(conn, font_cookie, NULL);
    
    if (font_reply) {
        printf("✅ Информация о шрифте:\n");
        printf("   Ascent: %d, Descent: %d\n", font_reply->font_ascent, font_reply->font_descent);
        printf("   Min bounds: width=%d, height=%d\n", 
               font_reply->min_bounds.character_width,
               font_reply->min_bounds.ascent + font_reply->min_bounds.descent);
        printf("   Max bounds: width=%d, height=%d\n",
               font_reply->max_bounds.character_width,
               font_reply->max_bounds.ascent + font_reply->max_bounds.descent);
        free(font_reply);
    } else {
        printf("❌ Ошибка получения информации о шрифте\n");
    }

    // GC для белого фона
    uint32_t bg_vals[] = { screen->white_pixel };
    gc_bg = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_bg, window, XCB_GC_FOREGROUND, bg_vals);

    // GC для текста с шрифтом и фоном
    uint32_t text_vals[] = { screen->black_pixel, screen->white_pixel, font };
    gc_text = xcb_generate_id(conn);
    xcb_create_gc(conn, gc_text, window, XCB_GC_FOREGROUND | XCB_GC_BACKGROUND | XCB_GC_FONT, text_vals);

    // Показ окна
    xcb_map_window(conn, window);
    xcb_flush(conn);
    printf("✅ Окно показано для вывода текста\n");

    // Цикл событий с рисованием текста
    xcb_generic_event_t *event;
    printf("🎯 Нажмите любую клавишу для выхода\n");
    
    while ((event = xcb_wait_for_event(conn))) {
        uint8_t type = event->response_type & ~0x80;
        
        if (type == XCB_EXPOSE) {
            // Очистка окна белым фоном
            xcb_rectangle_t bg_rect = { 0, 0, 500, 300 };
            xcb_poly_fill_rectangle(conn, window, gc_bg, 1, &bg_rect);
            
            // Вывод текста в разных позициях (используем более простые строки)
            const char *text1 = "Hello XCB Fonts!";
            const char *text2 = "Test fonts XCB";  
            const char *text3 = "abcdefghijklm";
            const char *text4 = "ABCDEFGHIJKLM";
            const char *text5 = "0123456789";
            
            // Попробуем разные способы вывода
            xcb_image_text_8(conn, strlen(text1), window, gc_text, 50, 50, text1);
            xcb_image_text_8(conn, strlen(text2), window, gc_text, 50, 80, text2);
            xcb_image_text_8(conn, strlen(text3), window, gc_text, 20, 120, text3);
            xcb_image_text_8(conn, strlen(text4), window, gc_text, 20, 150, text4);
            xcb_image_text_8(conn, strlen(text5), window, gc_text, 20, 180, text5);
            
            // Дополнительная информация
            char info[100];
            snprintf(info, sizeof(info), "Font ID: %d, Screen: %dx%d", 
                     font, screen->width_in_pixels, screen->height_in_pixels);
            xcb_image_text_8(conn, strlen(info), window, gc_text, 20, 220, info);
            
            xcb_flush(conn);
            printf("📝 Текст нарисован в окне\n");
        } 
        else if (type == XCB_KEY_PRESS) {
            free(event);
            break;
        }
        free(event);
    }

    // Очистка
    xcb_close_font(conn, font);
    xcb_free_gc(conn, gc_text);
    xcb_free_gc(conn, gc_bg);
    xcb_destroy_window(conn, window);
    xcb_disconnect(conn);

    printf("✅ Тест шрифтов завершен\n");
    return 0;
}