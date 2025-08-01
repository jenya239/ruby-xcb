#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void test_colors(xcb_connection_t *conn, xcb_screen_t *screen, xcb_window_t window) {
    printf("🎨 Тестирую цвета...\n");
    
    // Создание колормапа
    xcb_colormap_t colormap = xcb_generate_id(conn);
    xcb_create_colormap(conn, XCB_COLORMAP_ALLOC_NONE, colormap, window, screen->root_visual);
    
    // Выделение красного цвета
    xcb_alloc_color_cookie_t color_cookie = xcb_alloc_color(conn, colormap, 65535, 0, 0);
    xcb_alloc_color_reply_t *color_reply = xcb_alloc_color_reply(conn, color_cookie, NULL);
    
    if (color_reply) {
        printf("✅ Красный цвет: pixel=%d\n", color_reply->pixel);
        free(color_reply);
    } else {
        printf("❌ Ошибка выделения цвета\n");
    }
    
    xcb_free_colormap(conn, colormap);
}

void test_fonts(xcb_connection_t *conn) {
    printf("🔤 Тестирую шрифты...\n");
    
    xcb_font_t font = xcb_generate_id(conn);
    xcb_open_font(conn, font, 5, "fixed");
    xcb_flush(conn);
    
    // Запрос информации о шрифте
    xcb_query_font_cookie_t font_cookie = xcb_query_font(conn, font);
    xcb_query_font_reply_t *font_reply = xcb_query_font_reply(conn, font_cookie, NULL);
    
    if (font_reply) {
        printf("✅ Шрифт loaded: ascent=%d, descent=%d\n", 
               font_reply->font_ascent, font_reply->font_descent);
        free(font_reply);
    } else {
        printf("❌ Ошибка загрузки шрифта\n");
    }
    
    xcb_close_font(conn, font);
}

void test_cursor(xcb_connection_t *conn, xcb_screen_t *screen, xcb_window_t window) {
    printf("🖱️ Тестирую курсор...\n");
    
    // Создание простого курсора
    xcb_pixmap_t cursor_pixmap = xcb_generate_id(conn);
    xcb_pixmap_t mask_pixmap = xcb_generate_id(conn);
    
    xcb_create_pixmap(conn, 1, cursor_pixmap, window, 16, 16);
    xcb_create_pixmap(conn, 1, mask_pixmap, window, 16, 16);
    
    xcb_cursor_t cursor = xcb_generate_id(conn);
    xcb_create_cursor(conn, cursor, cursor_pixmap, mask_pixmap, 
                      0, 0, 65535, 8, 8, 65535, 65535, 65535);
    
    printf("✅ Курсор создан: %d\n", cursor);
    
    xcb_free_cursor(conn, cursor);
    xcb_free_pixmap(conn, cursor_pixmap);
    xcb_free_pixmap(conn, mask_pixmap);
}

void test_grab_input(xcb_connection_t *conn, xcb_window_t window) {
    printf("⌨️ Тестирую захват ввода...\n");
    
    // Захват указателя
    xcb_grab_pointer_cookie_t grab_cookie = xcb_grab_pointer(conn, 0, window, 
        XCB_EVENT_MASK_BUTTON_PRESS, XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC,
        XCB_NONE, XCB_NONE, XCB_CURRENT_TIME);
    
    xcb_grab_pointer_reply_t *grab_reply = xcb_grab_pointer_reply(conn, grab_cookie, NULL);
    if (grab_reply) {
        printf("✅ Указатель захвачен: status=%d\n", grab_reply->status);
        free(grab_reply);
        xcb_ungrab_pointer(conn, XCB_CURRENT_TIME);
    }
    
    // Запрос позиции указателя
    xcb_query_pointer_cookie_t pointer_cookie = xcb_query_pointer(conn, window);
    xcb_query_pointer_reply_t *pointer_reply = xcb_query_pointer_reply(conn, pointer_cookie, NULL);
    
    if (pointer_reply) {
        printf("✅ Позиция указателя: (%d, %d)\n", pointer_reply->win_x, pointer_reply->win_y);
        free(pointer_reply);
    }
}

void test_properties(xcb_connection_t *conn, xcb_window_t window) {
    printf("🏷️ Тестирую свойства...\n");
    
    // Интернирование атома
    xcb_intern_atom_cookie_t atom_cookie = xcb_intern_atom(conn, 0, 8, "WM_CLASS");
    xcb_intern_atom_reply_t *atom_reply = xcb_intern_atom_reply(conn, atom_cookie, NULL);
    
    if (atom_reply) {
        printf("✅ Атом WM_CLASS: %d\n", atom_reply->atom);
        
        // Установка свойства
        const char *class_name = "TestApp\0TestClass\0";
        xcb_change_property(conn, XCB_PROP_MODE_REPLACE, window, atom_reply->atom,
                           XCB_ATOM_STRING, 8, 20, class_name);
        
        printf("✅ Свойство установлено\n");
        free(atom_reply);
    }
}

void test_extensions(xcb_connection_t *conn) {
    printf("🔌 Тестирую расширения...\n");
    
    // Запрос расширения BIG-REQUESTS
    xcb_query_extension_cookie_t ext_cookie = xcb_query_extension(conn, 12, "BIG-REQUESTS");
    xcb_query_extension_reply_t *ext_reply = xcb_query_extension_reply(conn, ext_cookie, NULL);
    
    if (ext_reply) {
        printf("✅ BIG-REQUESTS: present=%d, major=%d, first_event=%d\n", 
               ext_reply->present, ext_reply->major_opcode, ext_reply->first_event);
        free(ext_reply);
    }
    
    // Список всех расширений
    xcb_list_extensions_cookie_t list_cookie = xcb_list_extensions(conn);
    xcb_list_extensions_reply_t *list_reply = xcb_list_extensions_reply(conn, list_cookie, NULL);
    
    if (list_reply) {
        printf("✅ Всего расширений: %d\n", list_reply->names_len);
        free(list_reply);
    }
}

int main() {
    xcb_connection_t *conn;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_gcontext_t gc;

    printf("=== Комплексный тест XCB ===\n");

    // Подключение
    conn = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(conn)) {
        printf("❌ Ошибка подключения\n");
        return 1;
    }

    screen = xcb_setup_roots_iterator(xcb_get_setup(conn)).data;
    printf("✅ Подключен к экрану: %dx%d\n", screen->width_in_pixels, screen->height_in_pixels);

    // Создание окна
    uint32_t values[] = { XCB_EVENT_MASK_EXPOSURE };
    window = xcb_generate_id(conn);
    xcb_create_window(conn, XCB_COPY_FROM_PARENT, window, screen->root,
                      100, 100, 300, 200, 1, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, XCB_CW_EVENT_MASK, values);

    xcb_map_window(conn, window);
    xcb_flush(conn);

    // Выполнение всех тестов
    test_colors(conn, screen, window);
    test_fonts(conn);
    test_cursor(conn, screen, window);
    test_grab_input(conn, window);
    test_properties(conn, window);
    test_extensions(conn);

    printf("\n🎯 Комплексный тест завершен!\n");
    printf("Нажмите Enter для закрытия...\n");
    getchar();

    // Очистка
    xcb_destroy_window(conn, window);
    xcb_disconnect(conn);

    return 0;
}