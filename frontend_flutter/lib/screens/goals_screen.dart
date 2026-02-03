import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String goalType = 'Поддерживать вес';
  double targetCalories = 2000;
  int weeklyGoal = 3;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      goalType = prefs.getString('nutrition_goal_type') ?? goalType;
      targetCalories = prefs.getDouble('nutrition_target_calories') ?? targetCalories;
      weeklyGoal = prefs.getInt('weekly_activity_goal') ?? weeklyGoal;
      loading = false;
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nutrition_goal_type', goalType);
    await prefs.setDouble('nutrition_target_calories', targetCalories);
    await prefs.setInt('weekly_activity_goal', weeklyGoal);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Цели сохранены'), backgroundColor: Colors.green));
  }

  Future<void> _editDialog() async {
    final calCtrl = TextEditingController(text: targetCalories.toStringAsFixed(0));
    String localGoal = goalType;
    int localWeekly = weeklyGoal;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDialog) {
        return AlertDialog(
          title: const Text('Изменить цели'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Тип цели'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: ['Похудение', 'Поддерживать вес', 'Набор массы'].map((t) {
                  final sel = t == localGoal;
                  return ChoiceChip(label: Text(t), selected: sel, onSelected: (_) => setStateDialog(() => localGoal = t));
                }).toList()),
                const SizedBox(height: 12),
                const Text('Целевые калории'),
                TextField(controller: calCtrl, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                const Text('Недельная цель'),
                Row(
                  children: [
                    IconButton(onPressed: () => setStateDialog(() => localWeekly = (localWeekly - 1).clamp(0, 21)), icon: const Icon(Icons.remove)),
                    Text('$localWeekly', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => setStateDialog(() => localWeekly = (localWeekly + 1).clamp(0, 21)), icon: const Icon(Icons.add)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () {
              final val = double.tryParse(calCtrl.text) ?? targetCalories;
              targetCalories = val;
              goalType = localGoal;
              weeklyGoal = localWeekly;
              Navigator.pop(ctx, true);
            }, child: const Text('Сохранить')),
          ],
        );
      }),
    );

    if (ok == true) {
      await _saveGoals();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Мои цели питания'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Тип цели', style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Text(goalType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Целевые калории', style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Text('${targetCalories.toStringAsFixed(0)} ккал', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.trending_up, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Недельная цель: $weeklyGoal'),
                    const Spacer(),
                    ElevatedButton.icon(onPressed: _editDialog, icon: const Icon(Icons.edit), label: const Text('Изменить')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: Center(child: Text('Здесь можно показывать прогресс в деталях и советы, связанные с выбранной целью', style: TextStyle(color: Colors.grey[600])))),
          ],
        ),
      ),
    );
  }
}
