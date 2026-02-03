import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  String? _email;
  String? _name;
  double _weight = 0;
  double _targetCalories = 2000;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final name = prefs.getString('name') ?? 'Пользователь';
    final weight = prefs.getDouble('weight') ?? 0;
    final targetCalories = prefs.getDouble('target_calories') ?? 2000;

    List<Map<String, dynamic>> hist = [];
    if (email != null) {
      final raw = prefs.getString('meal_history_$email');
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          hist = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (_) {
          hist = [];
        }
      }
    }

    setState(() {
      _email = email;
      _name = name;
      _weight = weight;
      _targetCalories = targetCalories;
      _history = hist;
      _loading = false;
    });
  }

  Future<void> _saveTargetCalories(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('target_calories', value);
    setState(() => _targetCalories = value);
  }

  Future<void> _clearAllHistory() async {
    if (_email == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('meal_history_$_email');
    setState(() => _history = []);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('История очищена')));
  }

  Future<void> _deleteEntry(int index) async {
    if (_email == null) return;
    _history.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meal_history_$_email', jsonEncode(_history));
    setState(() {});
  }

  Map<String, double> _computeAverages() {
    if (_history.isEmpty) {
      return {'calories': 0, 'proteins': 0, 'fats': 0, 'carbs': 0};
    }
    double c = 0, p = 0, f = 0, ch = 0;
    for (var e in _history) {
      final totals = e['totals'] as Map<String, dynamic>? ?? {};
      c += (totals['calories'] ?? 0).toDouble();
      p += (totals['proteins'] ?? 0).toDouble();
      f += (totals['fats'] ?? 0).toDouble();
      ch += (totals['carbs'] ?? 0).toDouble();
    }
    final n = _history.length;
    return {
      'calories': c / n,
      'proteins': p / n,
      'fats': f / n,
      'carbs': ch / n
    };
  }

  @override
  Widget build(BuildContext context) {
    final averages = _computeAverages();
    final progress = _targetCalories > 0
        ? (averages['calories']! / _targetCalories).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой прогресс'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          if (!_loading && _history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _clearAllHistory,
              tooltip: 'Очистить историю',
            )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _profileCard(),
                    const SizedBox(height: 16),
                    _goalCard(progress, percent, averages),
                    const SizedBox(height: 16),
                    _averageCards(averages),
                    const SizedBox(height: 20),
                    _historyCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _profileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundImage:
                  NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name ?? 'Пользователь',
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_email ?? 'Гость', style: const TextStyle(color: Colors.grey)),
                  Text(
                      'Вес: ${_weight > 0 ? _weight.toStringAsFixed(1) + " кг" : "не указан"}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(double progress, String percent, Map<String, double> averages) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Цель по калориям:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _changeGoalDialog,
                child: const Text('Изменить'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: progress >= 1 ? Colors.green : Colors.orangeAccent,
            minHeight: 12,
          ),
          const SizedBox(height: 8),
          Text(
              'Вы достигли $percent% (${averages['calories']!.toStringAsFixed(0)} / ${_targetCalories.toStringAsFixed(0)} ккал)'),
        ]),
      ),
    );
  }

  Future<void> _changeGoalDialog() async {
    final controller = TextEditingController(text: _targetCalories.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить цель'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Введите калории'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 2000;
              Navigator.pop(ctx, val);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null) await _saveTargetCalories(result);
  }

  Widget _averageCards(Map<String, double> averages) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _metricCard('Калории', '${averages['calories']!.toStringAsFixed(0)}', Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _metricCard('Белки', '${averages['proteins']!.toStringAsFixed(1)} г', Colors.blue)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _metricCard('Жиры', '${averages['fats']!.toStringAsFixed(1)} г', Colors.pink)),
          const SizedBox(width: 8),
          Expanded(child: _metricCard('Углеводы', '${averages['carbs']!.toStringAsFixed(1)} г', Colors.brown)),
        ]),
      ],
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _historyCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Последние записи',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Пусто — сохраните план в планировщике',
                  style: TextStyle(color: Colors.grey)),
            ),
          if (_history.isNotEmpty)
            ..._history.reversed.take(8).map((e) => _historyTile(e)).toList(),
        ]),
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> e) {
    final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime.now();
    final totals = e['totals'] as Map<String, dynamic>? ?? {};
    final cal = (totals['calories'] ?? 0).toDouble();

    return ListTile(
      title: Text('${date.day}.${date.month}.${date.year}'),
      subtitle: Text('Калории: ${cal.toStringAsFixed(0)}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.redAccent),
        onPressed: () => _confirmDelete(_history.indexOf(e)),
      ),
    );
  }

  Future<void> _confirmDelete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись'),
        content: const Text('Вы уверены, что хотите удалить эту запись?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) await _deleteEntry(index);
  }
}
