import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/injection/injection_container.dart';
import '../../domain/entities/user_habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../widgets/habit_card.dart';

@RoutePage()
class EditHabitPage extends StatefulWidget {
  final UserHabit userHabit;

  const EditHabitPage({
    super.key,
    required this.userHabit,
  });

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  final HabitRepository _repository = getIt<HabitRepository>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _notesController;
  bool _isSubmitting = false;
  bool _hasChanges = false;

  late String _repeatPeriod;
  late String _frequency;
  late List<int> _frequencyDays;
  late String _color;
  late String _icon;

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
    '🏃',
    '🚶',
    '🚴',
    '🥗',
    '💊',
    '☕',
    '🍵',
    '🧹',
    '🪴',
    '🎨',
    '🎸',
    '💻'
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
    _notesController = TextEditingController(text: widget.userHabit.notes);
    _repeatPeriod = widget.userHabit.repeatPeriod;
    _frequency = widget.userHabit.frequency;
    _frequencyDays = widget.userHabit.frequencyDays ?? [];
    _color = widget.userHabit.color;
    _icon = widget.userHabit.icon;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _repository.updateHabit(
        widget.userHabit.id,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Perubahan?'),
        content: const Text(
            'Ada perubahan yang belum disimpan. Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('TETAP DISINI'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'BUANG',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          context.router.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Habit'),
          actions: [
            if (_hasChanges && !_isSubmitting)
              TextButton(
                onPressed: _saveChanges,
                child: const Text('SIMPAN'),
              ),
          ],
        ),
        body: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preview Header
                      Text(
                        'Preview',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      HabitCard(
                        userHabit: widget.userHabit.copyWith(
                          icon: _icon,
                          color: _color,
                          notes: _notesController.text,
                          frequency: _frequency,
                          frequencyDays: _frequencyDays,
                        ),
                        onToggle: () {}, // No-op in preview
                      ),
                      const SizedBox(height: 24),

                      // Notes Section
                      Text(
                        'Catatan',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Tambahkan catatan...',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 2,
                        onChanged: (_) => _onChanged(),
                      ),
                      const SizedBox(height: 24),

                      // Schedule Section
                      Text(
                        'Jadwal & Frekuensi',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildScheduleCard(colorScheme),
                      const SizedBox(height: 24),

                      // Personalization Section
                      Text(
                        'Personalisasi',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPersonalizationCard(colorScheme),
                      const SizedBox(height: 40),

                      FilledButton(
                        onPressed: _isSubmitting ? null : _saveChanges,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_isSubmitting
                            ? 'MENYIMPAN...'
                            : 'SIMPAN PERUBAHAN'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildScheduleCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDropdownRow(
            label: 'Durasi Commit',
            value: _repeatPeriod,
            options: _repeatPeriodOptions,
            displayMapper: _formatRepeatPeriod,
            onChanged: (val) {
              setState(() => _repeatPeriod = val);
              _onChanged();
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDropdownRow(
            label: 'Frekuensi',
            value: _frequency,
            options: _frequencyOptions,
            displayMapper: _formatFrequency,
            onChanged: (val) {
              setState(() {
                _frequency = val;
                if (val != 'custom') _frequencyDays = [];
              });
              _onChanged();
            },
          ),
          if (_frequency == 'custom') ...[
            const SizedBox(height: 16),
            _buildCustomDaysPicker(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> options,
    required String Function(String) displayMapper,
    required Function(String) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: options.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(displayMapper(e)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildCustomDaysPicker(ColorScheme colorScheme) {
    return Wrap(
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
            _onChanged();
          },
        );
      }),
    );
  }

  Widget _buildPersonalizationCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Warna', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colorOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final colorHex = _colorOptions[index];
                final isSelected = _color == colorHex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _color = colorHex);
                    _onChanged();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(colorHex),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colorScheme.primary, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _iconOptions.length,
            itemBuilder: (context, index) {
              final icon = _iconOptions[index];
              final isSelected = _icon == icon;
              return GestureDetector(
                onTap: () {
                  setState(() => _icon = icon);
                  _onChanged();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _parseColor(_color).withOpacity(0.2)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: _parseColor(_color), width: 2)
                        : Border.all(
                            color: colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
