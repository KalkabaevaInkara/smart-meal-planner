import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final ingList = recipe.ingredients.where((i) => i.name.trim().isNotEmpty).toList();
    final ingNames = ingList.map((i) => i.name).toList();
    const int previewCount = 6;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFCE8D8)], // мягкие тёплые тона
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).pushNamed('/recipe', arguments: recipe);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🥗 Картинка
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  recipe.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 400,  // ✅ Кэшируем только нужный размер
                  cacheHeight: 225,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (context, error, st) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.fastfood, size: 56, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // 🍎 Информация
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Краткое описание
                  Text(
                    recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6D4C41)),
                  ),
                  const SizedBox(height: 8),

                  // 🧂 Ингредиенты — отображаем как чипы
                  if (ingNames.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...ingNames.take(previewCount).map((ing) => Chip(
                              label: Text(ing, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.green.shade50,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )),
                        if (ingNames.length > previewCount)
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (ctx) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                                        ),
                                        const SizedBox(height: 12),
                                        Text('Ингредиенты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                                        const SizedBox(height: 12),
                                        Flexible(
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            itemCount: ingList.length,
                                            separatorBuilder: (_, __) => const Divider(height: 8),
                                            itemBuilder: (context, idx) {
                                              final ing = ingList[idx];
                                              return ListTile(
                                                title: Text(ing.name),
                                                subtitle: Text('Кал: ${ing.caloriesPer100g} ккал/100г • Б ${ing.proteins} г • Ж ${ing.fats} г • У ${ing.carbs} г'),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.copy, size: 20),
                                                  onPressed: () {
                                                    Clipboard.setData(ClipboardData(text: ing.name));
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ингредиент скопирован')));
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Chip(
                              label: Text('+${ingNames.length - previewCount} ещё', style: const TextStyle(fontSize: 12, color: Colors.green)),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.green.shade100),
                            ),
                          ),
                      ],
                    )
                  else
                    const Text(
                      'Ингредиенты не указаны',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                  const SizedBox(height: 10),

                  // 🔥 Калории / время / белки
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoIcon('🔥', '${recipe.calories} ккал'),
                      _infoIcon('⏱', '${recipe.cookingTime} мин'),
                      _infoIcon('💪', '${recipe.proteins} г'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoIcon(String icon, String text) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6D4C41),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
