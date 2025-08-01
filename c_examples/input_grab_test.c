#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    xcb_connection_t *conn;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_gcontext_t gc;

    printf("=== XCB Input Grab Test ===\n");

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
        XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_BUTTON_PRESS
    };
    
    window = xcb_generate_id(conn);
    xcb_create_window(conn, XCB_COPY_FROM_PARENT, window, screen->root,
                      100, 100, 500, 300, 2, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, 
                      XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK, values);

    // GC для текста
    uint32_t gc_vals[] = { screen->black_pixel };
    gc = xcb_generate_id(conn);
    xcb_create_gc(conn, gc, window, XCB_GC_FOREGROUND, gc_vals);

    // Показ окна
    xcb_map_window(conn, window);
    xcb_flush(conn);
    printf("✅ Окно показано\n");

    // Цикл событий с тестами захвата
    xcb_generic_event_t *event;
    int stage = 1;
    
    printf("\n🎯 Этап %d: Обычные события (клик в окне или нажмите клавишу)\n", stage);
    
    while ((event = xcb_wait_for_event(conn))) {
        uint8_t type = event->response_type & ~0x80;
        
        if (type == XCB_EXPOSE) {
            xcb_clear_area(conn, 0, window, 0, 0, 500, 300);
            xcb_flush(conn);
            printf("🖼️ Окно очищено\n");
        } 
        else if (type == XCB_KEY_PRESS) {
            printf("⌨️ Клавиша нажата (этап %d)\n", stage);
            
            if (stage == 1) {
                // Переходим к захвату указателя
                stage = 2;
                printf("\n🎯 Этап %d: Захват указателя...\n", stage);
                
                xcb_grab_pointer_cookie_t grab_cookie = xcb_grab_pointer(
                    conn, 0, window,
                    XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE,
                    XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC,
                    XCB_NONE, XCB_NONE, XCB_CURRENT_TIME);
                
                xcb_grab_pointer_reply_t *grab_reply = xcb_grab_pointer_reply(conn, grab_cookie, NULL);
                if (grab_reply) {
                    printf("✅ Указатель захвачен, status: %d\n", grab_reply->status);
                    printf("🖱️ Кликните где угодно на экране - события будут приходить в наше окно\n");
                    free(grab_reply);
                } else {
                    printf("❌ Ошибка захвата указателя\n");
                }
                
            } else if (stage == 2) {
                // Освобождение указателя и захват клавиатуры
                stage = 3;
                xcb_ungrab_pointer(conn, XCB_CURRENT_TIME);
                printf("✅ Указатель освобожден\n");
                
                printf("\n🎯 Этап %d: Захват клавиатуры...\n", stage);
                
                xcb_grab_keyboard_cookie_t kb_grab_cookie = xcb_grab_keyboard(
                    conn, 0, window, XCB_CURRENT_TIME,
                    XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC);
                
                xcb_grab_keyboard_reply_t *kb_grab_reply = xcb_grab_keyboard_reply(conn, kb_grab_cookie, NULL);
                if (kb_grab_reply) {
                    printf("✅ Клавиатура захвачена, status: %d\n", kb_grab_reply->status);
                    printf("⌨️ Печатайте - все клавиши будут приходить в наше окно\n");
                    free(kb_grab_reply);
                } else {
                    printf("❌ Ошибка захвата клавиатуры\n");
                }
                
            } else {
                // Завершение
                xcb_ungrab_keyboard(conn, XCB_CURRENT_TIME);
                printf("✅ Клавиатура освобождена\n");
                free(event);
                break;
            }
        }
        else if (type == XCB_BUTTON_PRESS) {
            printf("🖱️ Кнопка мыши нажата (этап %d)\n", stage);
            
            if (stage == 2) {
                // Проверка позиции указателя во время захвата
                xcb_query_pointer_cookie_t pointer_cookie = xcb_query_pointer(conn, window);
                xcb_query_pointer_reply_t *pointer_reply = xcb_query_pointer_reply(conn, pointer_cookie, NULL);
                
                if (pointer_reply) {
                    printf("📍 Позиция указателя: (%d, %d) относительно окна\n", 
                           pointer_reply->win_x, pointer_reply->win_y);
                    printf("📍 Позиция на экране: (%d, %d)\n", 
                           pointer_reply->root_x, pointer_reply->root_y);
                    free(pointer_reply);
                }
            }
        }
        
        free(event);
    }

    // Очистка
    xcb_free_gc(conn, gc);
    xcb_destroy_window(conn, window);
    xcb_disconnect(conn);

    printf("✅ Тест захвата ввода завершен\n");
    return 0;
}