import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

@RoutePage()
class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HabitRepository _repository = getIt<HabitRepository>();
  final _formKey = GlobalKey<FormState>();
  
  // Custom Habit Form
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addCatalogHabit(Habit habit) async {
    setState(() => _isSubmitting = true);
    try {
      await _repository.addHabit(habit.id);
      if (mounted) {
        context.router.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createCustomHabit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      await _repository.createCustomHabit(
        _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (mounted) {
        context.router.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Habit'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Katalog'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: _isSubmitting 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogTab(),
                _buildCustomTab(),
              ],
            ),
    );
  }

  Widget _buildCatalogTab() {
    return FutureBuilder<List<Habit>>(
      future: _repository.getHabitCatalog(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final habits = snapshot.data ?? [];
        if (habits.isEmpty) {
          return const Center(child: Text('Katalog kosong.'));
        }

        return ListView.builder(
          itemCount: habits.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final habit = habits[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: habit.description != null ? Text(habit.description!) : null,
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => _addCatalogHabit(habit),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Habit',
                hintText: 'Contoh: Minum Air 2L',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama habit wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _createCustomHabit,
              child: const Text('Buat Custom Habit'),
            ),
          ],
        ),
      ),
    );
  }
}
