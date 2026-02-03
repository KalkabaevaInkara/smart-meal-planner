import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NutritionTipsScreen extends StatelessWidget {
  const NutritionTipsScreen({super.key});

  final List<Map<String, String>> _tips = const [
    {
      'title': 'Белок при каждом приёме',
      'body': 'Добавляйте источник белка в каждый приём пищи — курица, рыба, бобовые или яйца.'
    },
    {
      'title': 'Пейте воду',
      'body': 'Начинайте день со стакана воды и держите бутылку с собой — гидратация помогает контролю аппетита.'
    },
    {
      'title': 'Цветная тарелка',
      'body': 'Старайтесь заполнять половину тарелки овощами разного цвета — витамины и клетчатка.'
    },
    {
      'title': 'Снизьте сахара',
      'body': 'Замените сладости на фрукты или горсть орехов — это снизит резкие скачки сахара.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Советы по питанию'),
        backgroundColor: Colors.green,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final tip = _tips[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ExpansionTile(
              leading: const Icon(Icons.restaurant_menu, color: Colors.green),
              title: Text(tip['title']!),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(tip['body']!),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: tip['body']!)); // ✅ добавлен !
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Совет скопирован')),
                        );
                      },
                      child: const Text('Копировать'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
