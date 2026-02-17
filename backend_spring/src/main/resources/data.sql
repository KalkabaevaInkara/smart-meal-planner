-- ================= USERS =================
INSERT INTO users (full_name, email, password, role) VALUES
('Инкара Калкабаева', '[inkara@example.com](mailto:inkara@example.com)', 'hashed_password', 'USER'),
('Администратор', '[admin@mail.com](mailto:admin@mail.com)', 'admin123', 'ADMIN');

-- ================= DIETS =================
INSERT INTO diets (name, description) VALUES
('Сбалансированная', 'Оптимальное сочетание белков, жиров и углеводов'),
('Кето', 'Минимум углеводов, больше жиров и белков'),
('Вегетарианская', 'Без мяса, но с молочными продуктами'),
('Веганская', 'Без продуктов животного происхождения'),
('Средиземноморская', 'Много овощей, рыбы и оливкового масла'),
('Низкокалорийная', 'Подходит для похудения');

-- ================= INGREDIENTS =================
INSERT INTO ingredients (name, calories_per100g, proteins, fats, carbs) VALUES
('Куриная грудка',165,31,3.6,0),
('Овсянка',370,13,7,68),
('Банан',89,1.1,0.3,23),
('Авокадо',160,2,15,9),
('Яйцо',155,13,11,1.1),
('Рис',360,7,0.6,79),
('Брокколи',34,2.8,0.4,7),
('Лосось',208,20,13,0),
('Творог',98,11,4.3,3),
('Орехи',650,15,60,15),
('Помидор',18,0.9,0.2,3.9),
('Огурец',15,0.7,0.1,3);

-- ================= RECIPES =================
-- ================= RECIPES =================
INSERT INTO recipes (title, description, calories, proteins, fats, carbs, image_url, diet_id, cooking_time, difficulty) VALUES
('Овсянка с бананом и орехами','Питательный завтрак',320,10,9,55,'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',1,10,'EASY'),
('Смузи из шпината и банана','Зелёный смузи',180,5,2,30,'https://images.unsplash.com/photo-1505253213348-cd54c92b37f6?w=800&q=80',4,5,'EASY'),
('Куриная грудка с брокколи','Белковое блюдо',250,35,6,8,'https://images.unsplash.com/photo-1604908176997-431b1e0f2b1b?w=800&q=80',2,25,'MEDIUM'),
('Салат с авокадо и лососем','Свежий салат',280,22,18,7,'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',5,15,'MEDIUM'),
('Творог с ягодами','Белковый перекус',150,16,3,10,'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',1,5,'EASY'),
('Овощной боул','Боул с овощами',310,12,8,45,'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80',4,20,'MEDIUM'),
('Рис с курицей и овощами','Классическое блюдо',400,30,10,55,'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=800&q=80',1,30,'MEDIUM'),
('Омлет с овощами','Белковый завтрак',210,14,15,5,'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=800&q=80',1,10,'EASY'),
('Фруктовый салат','Освежающий десерт',120,2,1,28,'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=800&q=80',4,10,'EASY'),
('Лосось с киноа','Полноценный ужин',450,32,20,30,'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80',5,25,'MEDIUM'),
('Греческий салат','Овощи и фета',220,6,17,12,'https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?w=800&q=80',5,10,'EASY'),
('Паста цельнозерновая','Много клетчатки',380,15,8,60,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=800&q=80',1,20,'MEDIUM'),
('Киноа с фруктами','Альтернатива овсянке',290,8,6,45,'https://images.unsplash.com/photo-1512058564366-c9e3e0467d5d?w=800&q=80',1,15,'EASY'),
('Тост с авокадо и яйцом','Заряд энергии',310,13,20,18,'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800&q=80',5,10,'EASY');

-- ================= RECIPE INGREDIENTS =================
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, amount_grams) VALUES
(1,2,50),(1,3,80),(1,10,20),
(3,1,120),(3,7,60),
(4,4,50),(4,8,80),
(5,9,100);

-- ================= MEAL PLAN =================
INSERT INTO meal_plans (user_id, plan_date, breakfast_id, lunch_id, dinner_id, total_calories) VALUES
(1, CURRENT_DATE, 1, 3, 4, 850),
(1, CURRENT_DATE - INTERVAL '1 day', 2, 7, 10, 950);

-- ================= USER PROGRESS =================
INSERT INTO user_progress (user_id, date, weight, calories_consumed, calories_burned) VALUES
(1, CURRENT_DATE - INTERVAL '6 day', 61.0, 1800, 300),
(1, CURRENT_DATE - INTERVAL '5 day', 60.8, 1750, 320),
(1, CURRENT_DATE - INTERVAL '4 day', 60.7, 1700, 310),
(1, CURRENT_DATE - INTERVAL '3 day', 60.5, 1600, 350),
(1, CURRENT_DATE - INTERVAL '2 day', 60.4, 1500, 370),
(1, CURRENT_DATE - INTERVAL '1 day', 60.3, 1450, 400),
(1, CURRENT_DATE, 60.1, 1400, 410);
