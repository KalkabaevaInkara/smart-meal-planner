# 🥗 Healthy Eating — Мобильное приложение для здорового питания

## 📋 Содержание
1. [Описание проекта](#описание-проекта)
2. [Структура проекта](#структура-проекта)
3. [Установка и запуск](#установка-и-запуск)
4. [API Эндпоинты](#api-эндпоинты)
5. [Структура БД](#структура-бд)
6. [Тестирование](#тестирование)
7. [Лучшие практики](#лучшие-практики)

---

## 📱 Описание проекта

**Healthy Eating** — кроссплатформенное мобильное приложение для планирования и отслеживания здорового питания, разработанное на **Flutter** с использованием **REST API** и **SharedPreferences**.

### Ключевые функции:
- ✅ Аутентификация (регистрация, вход, выход)
- ✅ Каталог рецептов с поиском и фильтрацией
- ✅ Планировщик питания (завтрак, обед, ужин)
- ✅ История питания и прогресс
- ✅ Цели по калорийности
- ✅ Советы по питанию
- ✅ Профиль пользователя

---

## 🏗️ Структура проекта

```
lib/
├── main.dart                      # Точка входа
├── app.dart                       # Конфигурация приложения
├── services/
│   └── api_service.dart           # API запросы с retry-логикой и логированием
├── models/
│   ├── recipe.dart                # Модель рецепта и ингредиента
│   ├── nutrients.dart             # Модель питательных веществ
│   └── meal_plan.dart             # Модель плана питания
├── screens/
│   ├── login_screen.dart          # Экран авторизации
│   ├── home_screen.dart           # Главный экран
│   ├── catalog_screen.dart        # Каталог рецептов
│   ├── planner_screen.dart        # Планировщик
│   ├── my_progress_screen.dart    # Прогресс
│   ├── profile_screen.dart        # Профиль
│   ├── goals_screen.dart          # Цели
│   ├── nutrition_tips_screen.dart # Советы
│   ├── meal_history_screen.dart   # История
│   └── recipe_detail_screen.dart  # Детали рецепта
└── widgets/
    └── recipe_card.dart           # Компонент карточки рецепта

test/
├── widget_test.dart               # UI тесты
└── api_service_test.dart          # Юнит-тесты API
```

---

## 🚀 Установка и запуск

### Конфигурация

Отредактируйте `lib/services/api_service.dart`:

```dart
static const String baseUrl = "http://172.20.10.5:8080";  // ✅ IP сервера
```

### Примеры запросов

- `POST http://172.20.10.5:8080/api/users/login`
- `GET http://172.20.10.5:8080/api/recipes`
- `GET http://172.20.10.5:8080/api/recipes/1`

---

## 🔌 API Эндпоинты

### Аутентификация

#### POST `/users/register`
Регистрация нового пользователя

**Запрос:**
```json
{
  "email": "user@example.com",
  "fullName": "John Doe",
  "password": "SecurePass123"
}
```

**Ответ (200-201):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "email": "user@example.com",
  "fullName": "John Doe",
  "role": "user"
}
```

**Ошибки:**
- 400: Email уже зарегистрирован
- 422: Некорректные данные

---

#### POST `/users/login`
Вход в систему

**Запрос:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Ответ (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "email": "user@example.com",
  "fullName": "John Doe"
}
```

**Ошибки:**
- 401: Неверные учетные данные
- 404: Пользователь не найден

---

#### GET `/users/profile`
Получение профиля (требует Authorization: Bearer {token})

**Ответ (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "fullName": "John Doe",
  "role": "user"
}
```

---

#### PUT `/users/profile`
Обновление профиля

**Запрос:**
```json
{
  "fullName": "Jane Doe"
}
```

**Ответ (200):**
```json
{
  "id": 1,
  "fullName": "Jane Doe",
  "email": "user@example.com"
}
```

---

### Рецепты

#### GET `/recipes`
Получение списка рецептов с фильтрацией

**Query параметры:**
- `search` (string): поиск по названию
- `difficulty` (string): "Легко", "Средне", "Сложно"
- `minCalories` (int): минимум калорий
- `maxCalories` (int): максимум калорий
- `maxCookingTime` (int): максимум времени готовки
- `sortBy` (string): сортировка "title", "calories", "time"

**Ответ (200):**
```json
[
  {
    "id": 1,
    "title": "Овсянка с ягодами",
    "description": "...",
    "calories": 320,
    "proteins": 10.0,
    "fats": 8.0,
    "carbs": 50.0,
    "cookingTime": 10,
    "difficulty": "Легко",
    "imageUrl": "...",
    "ingredients": [
      {
        "id": 1,
        "name": "Овсяные хлопья",
        "caloriesPer100g": 389,
        "proteins": 13.0,
        "fats": 6.0,
        "carbs": 66.0
      }
    ]
  }
]
```

---

## 🐞 Логи и отладка

Приложение сохраняет сетевые логи локально (SharedPreferences) для диагностики. Чтобы экспортировать или отправить логи:

- Откройте `Профиль` → раздел "Экспорт сетевых логов".
- Нажмите `Экспорт` чтобы записать логи в временный файл (временная директория платформы). Путь к файлу будет показан в уведомлении.
- Нажмите `Отправить` чтобы отправить JSON с логами на произвольный endpoint (введите URL).

Сценарии использования:
- При обращении в техподдержку можно отправить файл логов для анализа.
- Можно настроить endpoint на собственном сервере для централизованного сбора логов.


---

#### GET `/recipes/{id}`
Получение рецепта по ID

**Ответ (200):** см. выше одиночный рецепт

**Ошибки:**
- 404: Рецепт не найден

---

#### GET `/recipes/search`
Поиск рецептов

**Query:**
- `q` (string): поисковая строка

---

#### GET `/recipes/difficulties`
Получение списка сложностей

**Ответ (200):**
```json
["Легко", "Средне", "Сложно"]
```

---

#### GET `/recipes/stats`
Статистика рецептов

**Ответ (200):**
```json
{
  "total": 150,
  "avgCalories": 350.5,
  "avgCookingTime": 25
}
```

---

### Ингредиенты

#### GET `/ingredients`
Получение всех ингредиентов

**Ответ (200):**
```json
[
  {
    "id": 1,
    "name": "Курица",
    "caloriesPer100g": 165,
    "proteins": 31.0,
    "fats": 3.6,
    "carbs": 0.0
  }
]
```

---

### Диеты

#### GET `/diets`
Получение списка диет

**Ответ (200):**
```json
[
  {
    "id": 1,
    "name": "Кетогенная",
    "description": "..."
  }
]
```

---

#### GET `/recipes/by-diet`
Рецепты по типу диеты

**Query:**
- `diet` (string): название диеты

---

## 💾 Структура БД

### Локальное хранилище (SharedPreferences)

```
auth_token         → string (JWT токен)
user_role          → string ("user", "admin")
fullName           → string (ФИО пользователя)
email              → string (Email)
nutrition_goal_type    → string ("Похудение", "Поддерживать", "Набор")
nutrition_target_calories → double (целевые калории)
weekly_activity_goal    → int (недельная цель)
weight             → double (вес пользователя)
meal_plan_${email} → JSON string
  {
    "breakfast": int (recipe_id),
    "lunch": int,
    "dinner": int
  }
meal_history_${email} → JSON array
  [
    {
      "date": ISO8601 string,
      "breakfast": int,
      "lunch": int,
      "dinner": int,
      "totals": {
        "calories": double,
        "proteins": double,
        "fats": double,
        "carbs": double
      }
    }
  ]
```

### Серверная БД (примерная структура)

#### Users
```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  fullName VARCHAR(255),
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('user', 'admin') DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Recipes
```sql
CREATE TABLE recipes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  calories INT,
  proteins FLOAT,
  fats FLOAT,
  carbs FLOAT,
  cookingTime INT,
  difficulty VARCHAR(50),
  imageUrl VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Ingredients
```sql
CREATE TABLE ingredients (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) UNIQUE NOT NULL,
  caloriesPer100g INT,
  proteins FLOAT,
  fats FLOAT,
  carbs FLOAT
);
```

#### Recipe_Ingredients
```sql
CREATE TABLE recipe_ingredients (
  recipe_id INT,
  ingredient_id INT,
  quantity FLOAT,
  FOREIGN KEY (recipe_id) REFERENCES recipes(id),
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
  PRIMARY KEY (recipe_id, ingredient_id)
);
```

---

## 🧪 Тестирование

### Запуск всех тестов

```bash
flutter test
```

### Запуск конкретного файла

```bash
flutter test test/api_service_test.dart
flutter test test/widget_test.dart
```

### Покрытие тестами

```bash
flutter test --coverage
open coverage/lcov-report/index.html  # macOS
start coverage/lcov-report/index.html  # Windows
```

### Типы тестов

#### 1. Юнит-тесты (Unit Tests)
Тестирование отдельных функций:
- Валидация email
- Валидация пароля
- Логирование

**Файл:** `test/api_service_test.dart`

#### 2. Виджет-тесты (Widget Tests)
Тестирование UI компонентов:
- Отображение экранов
- Навигация
- Интерактивность

**Файл:** `test/widget_test.dart`

#### 3. Интеграционные тесты
Тестирование полных сценариев (требует эмулятора/девайса)

```bash
flutter test integration_test/app_test.dart
```

---

## 📊 Логирование и мониторинг

### Включение логирования

```dart
import 'package:healthy_eating_flutter/services/api_service.dart';

// Получить логи
final logs = ApiService.getRequestLog();
for (var log in logs) {
  print(log);
}

// Очистить логи
ApiService.clearRequestLog();
```

### Пример логов

```
[2024-01-15T10:30:45.123] 📤 Вход: test@example.com
[2024-01-15T10:30:45.234] Попытка запроса 1/3
[2024-01-15T10:30:46.456] Запрос успешен: 200
[2024-01-15T10:30:46.567] ✅ Вход успешен
```

---

## 🛡️ Безопасность

### Валидация

- ✅ Email: проверка формата
- ✅ Пароль: минимум 8 символов + цифра
- ✅ Имя: минимум 2 символа
- ✅ ID рецепта: > 0

### Обработка ошибок

- ✅ Retry-логика (3 попытки)
- ✅ Exponential backoff (2, 4, 6 сек)
- ✅ Graceful fallbacks
- ✅ Timeout 15 секунд

---

## 📈 Производительность

### Оптимизация

- ✅ Асинхронные запросы
- ✅ Кэширование токена
- ✅ Кэширование данных локально
- ✅ Ленивая загрузка списков
- ✅ GridView/ListView оптимизация

### Метрики

- Время запуска: < 2 сек
- Время загрузки каталога: < 3 сек
- Размер приложения: ~50 МБ

---

## 🤝 Вклад

1. Fork репозитория
2. Создайте ветку (`git checkout -b feature/AmazingFeature`)
3. Commit изменений (`git commit -m 'Add AmazingFeature'`)
4. Push на ветку (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

---

## 📝 Лицензия

MIT License — см. файл LICENSE

---

## 👥 Контакты

- Email: support@healthyeating.app
- GitHub: https://github.com/yourrepo
- Документация API: http://api.healthyeating.app/docs

---

**Версия:** 1.0.0  
**Последнее обновление:** 15 января 2024
