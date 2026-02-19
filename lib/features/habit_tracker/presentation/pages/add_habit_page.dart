import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/injection/injection_container.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/entities/habit.dart';

@RoutePage()
class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final HabitRepository _repository = getIt<HabitRepository>();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  String _repeatPeriod = 'forever';
  String _frequency = 'daily';
  List<int> _frequencyDays = [];
  String _color = '#6366F1';
  String _icon = '⭐';
  bool _showAdvanced = false;

  static const List<String> _repeatPeriodOptions = [
    'forever',
    '1_day',
    '1_week',
    '1_month',
    '1_year',
  ];

  static const List<String> _frequencyOptions = ['daily', 'weekly', 'custom'];

  static const List<String> _colorOptions = [
    '#6366F1',
    '#8B5CF6',
    '#EC4899',
    '#EF4444',
    '#F97316',
    '#EAB308',
    '#22C55E',
    '#14B8A6',
    '#06B6D4',
    '#3B82F6',
  ];

  static const List<String> _iconOptions = [
    '⭐',
    '🔥',
    '💪',
    '📖',
    '🙏',
    '🧘',
    '🎯',
    '💧',
    '🌅',
    '🍎',
    '💤',
    '📝',
  ];

  static const List<String> _dayNames = [
    'Min',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
  ];

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
      await _repository.addHabit(
        habitId: habit.id,
        repeatPeriod: _repeatPeriod == 'forever' ? null : _repeatPeriod,
        frequency: _frequency,
        frequencyDays: _frequency == 'custom' ? _frequencyDays.join(',') : null,
        color: _color,
        icon: _icon,
      );
      if (mounted) {
        context.router.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        repeatPeriod: _repeatPeriod == 'forever' ? null : _repeatPeriod,
        frequency: _frequency,
        frequencyDays: _frequency == 'custom' ? _frequencyDays.join(',') : null,
        color: _color,
        icon: _icon,
      );
      if (mounted) {
        context.router.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatRepeatPeriod(String value) {
    switch (value) {
      case '1_day':
        return '1 Hari';
      case '1_week':
        return '1 Minggu';
      case '1_month':
        return '1 Bulan';
      case '1_year':
        return '1 Tahun';
      default:
        return 'Selamanya';
    }
  }

  String _formatFrequency(String value) {
    switch (value) {
      case 'daily':
        return 'Harian';
      case 'weekly':
        return 'Mingguan';
      case 'custom':
        return 'Custom';
      default:
        return value;
    }
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
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
              children: [_buildCatalogTab(), _buildCustomTab()],
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
              child: ExpansionTile(
                title: Text(
                  habit.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                    habit.description != null ? Text(habit.description!) : null,
                trailing: const Icon(Icons.add_circle_outline),
                children: [
                  _buildAdvancedOptions(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: () => _addCatalogHabit(habit),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Habit'),
                    ),
                  ),
                ],
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
            const SizedBox(height: 16),
            _buildAdvancedToggle(),
            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              _buildAdvancedOptions(),
            ],
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

  Widget _buildAdvancedToggle() {
    return InkWell(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              _showAdvanced ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _showAdvanced ? 'Sembunyikan Opsi' : 'Tampilkan Opsi Lainnya',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengaturan Habit',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildRepeatPeriodDropdown(),
          const SizedBox(height: 16),
          _buildFrequencyDropdown(),
          if (_frequency == 'custom') ...[
            const SizedBox(height: 16),
            _buildCustomDaysPicker(),
          ],
          const SizedBox(height: 24),
          const Text(
            'Personalisasi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildColorPicker(),
          const SizedBox(height: 16),
          _buildIconPicker(),
        ],
      ),
    );
  }

  Widget _buildRepeatPeriodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durasi Commit',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _repeatPeriod,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: _repeatPeriodOptions
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(_formatRepeatPeriod(e)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _repeatPeriod = value);
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frekuensi',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _frequency,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: _frequencyOptions
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(_formatFrequency(e)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _frequency = value;
                if (value != 'custom') _frequencyDays = [];
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCustomDaysPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Hari',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _frequencyDays.contains(index);
            return FilterChip(
              label: Text(_dayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _frequencyDays.add(index);
                    _frequencyDays.sort();
                  } else {
                    _frequencyDays.remove(index);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warna',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorOptions.map((color) {
            final isSelected = _color == color;
            return InkWell(
              onTap: () => setState(() => _color = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseColor(color),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ikon',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _iconOptions.map((icon) {
            final isSelected = _icon == icon;
            return InkWell(
              onTap: () => setState(() => _icon = icon),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _parseColor(_color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? _parseColor(_color) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
