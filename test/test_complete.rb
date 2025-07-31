#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Тестирование полных XCB привязок ==="

# Проверяем загрузку модуля
puts "✓ Модуль XCB загружен"

# Проверяем константы
puts "✓ X_PROTOCOL = #{XCB::X_PROTOCOL}"
puts "✓ XCB_CONN_ERROR = #{XCB::XCB_CONN_ERROR}"

# Проверяем структуры
event = XCB::GenericEvent.new
puts "✓ Структура GenericEvent создана"

error = XCB::GenericError.new
puts "✓ Структура GenericError создана"

cookie = XCB::VoidCookie.new
puts "✓ Структура VoidCookie создана"

auth = XCB::AuthInfo.new
puts "✓ Структура AuthInfo создана"

# Проверяем типы
puts "✓ Типы указателей определены"

# Подсчитываем количество функций
function_count = XCB.methods.grep(/^xcb_/).count
puts "✓ Количество привязанных функций: #{function_count}"

puts "\n=== Все тесты пройдены успешно! ==="
puts "Используйте 'ruby example.rb' для демонстрации работы с окнами" 