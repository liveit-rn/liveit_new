import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/injection/injection_container.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

@RoutePage()
class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage>
    with TickerProviderStateMixin {
  static const _contentPadding = EdgeInsets.symmetric(horizontal: 16);

  final HabitRepository _repository = getIt<HabitRepository>();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  late final TabController _tabController;
  late final AnimationController _animationController;

  bool _isSubmitting = false;
  bool _isLoadingCatalog = true;
  Object? _catalogError;
  List<Habit> _catalogHabits = const [];

  String _repeatPeriod = 'forever';
  String _frequency = 'daily';
  List<int> _frequencyDays = [];
  String _color = '#6366F1';
  String _icon = '⭐';
  bool _showCatalogSettings = false;

  static const List<String> _repeatPeriodOptions = [
    'forever',
    '1_day',
    '1_week',
    '1_month',
    '1_year',
  ];

  static const List<String> _frequencyOptions = ['daily', 'weekly', 'custom'];

  static const List<Map<String, String>> _colorOptions = [
    {'hex': '#6366F1', 'name': 'Indigo'},
    {'hex': '#8B5CF6', 'name': 'Violet'},
    {'hex': '#EC4899', 'name': 'Pink'},
    {'hex': '#EF4444', 'name': 'Red'},
    {'hex': '#F97316', 'name': 'Orange'},
    {'hex': '#EAB308', 'name': 'Yellow'},
    {'hex': '#22C55E', 'name': 'Green'},
    {'hex': '#14B8A6', 'name': 'Teal'},
    {'hex': '#06B6D4', 'name': 'Cyan'},
    {'hex': '#3B82F6', 'name': 'Blue'},
  ];

  static const List<Map<String, String>> _iconOptions = [
    {'emoji': '⭐', 'name': 'Star'},
    {'emoji': '🔥', 'name': 'Fire'},
    {'emoji': '💪', 'name': 'Strong'},
    {'emoji': '📖', 'name': 'Bible'},
    {'emoji': '🙏', 'name': 'Pray'},
    {'emoji': '🧘', 'name': 'Meditate'},
    {'emoji': '🎯', 'name': 'Target'},
    {'emoji': '💧', 'name': 'Water'},
    {'emoji': '🌅', 'name': 'Morning'},
    {'emoji': '🍎', 'name': 'Health'},
    {'emoji': '💤', 'name': 'Sleep'},
    {'emoji': '📝', 'name': 'Journal'},
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _titleController.addListener(_refreshPreview);
    _loadCatalog();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshPreview);
    _tabController.dispose();
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    try {
      final habits = await _repository.getHabitCatalog();
      if (!mounted) return;
      setState(() {
        _catalogHabits = habits;
        _isLoadingCatalog = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogError = error;
        _isLoadingCatalog = false;
      });
    }
  }

  Future<void> _addCatalogHabit(Habit habit) async {
    HapticFeedback.mediumImpact();
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

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      context.router.pop(true);
    } catch (error) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      _showErrorSnackBar('Gagal menambah habit: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _createCustomHabit() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _repository.createCustomHabit(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        repeatPeriod: _repeatPeriod == 'forever' ? null : _repeatPeriod,
        frequency: _frequency,
        frequencyDays: _frequency == 'custom' ? _frequencyDays.join(',') : null,
        color: _color,
        icon: _icon,
      );

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      context.router.pop(true);
    } catch (error) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      _showErrorSnackBar('Gagal membuat habit: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        return 'Setiap Hari';
      case 'weekly':
        return 'Mingguan';
      case 'custom':
        return 'Pilih Hari';
      default:
        return value;
    }
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  String _currentColorName() {
    return _colorOptions.firstWhere(
          (option) => option['hex'] == _color,
          orElse: () => {'name': 'Custom'},
        )['name'] ??
        'Custom';
  }

  String _currentIconName() {
    return _iconOptions.firstWhere(
          (option) => option['emoji'] == _icon,
          orElse: () => {'name': 'Icon'},
        )['name'] ??
        'Icon';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.03),
              colorScheme.surface,
              colorScheme.tertiary.withValues(alpha: 0.015),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildModeTabs(),
              const SizedBox(height: 8),
              Expanded(
                child: _isSubmitting
                    ? _buildSubmittingState()
                    : TabBarView(
                        controller: _tabController,
                        children: [_buildCatalogTab(), _buildCustomTab()],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              context.router.pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Habit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Bangun kebiasaan baik',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: _contentPadding,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(4),
        radius: 16,
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Katalog'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Menyimpan habit...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
    if (_isLoadingCatalog) {
      return _buildCenteredMessage(
        icon: Icons.sync_rounded,
        message: 'Memuat katalog...',
        loading: true,
      );
    }

    if (_catalogError != null) {
      return _buildCenteredMessage(
        icon: Icons.error_outline_rounded,
        message: 'Gagal memuat katalog',
        subtitle: _catalogError.toString(),
        actionLabel: 'Coba Lagi',
        onAction: _loadCatalog,
      );
    }

    if (_catalogHabits.isEmpty) {
      return _buildCenteredMessage(
        icon: Icons.folder_open_outlined,
        message: 'Katalog kosong',
        subtitle: 'Belum ada habit di katalog.',
      );
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = _animationController.value;
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: _buildCatalogSettingsCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Text(
                'Pilih habit dari katalog',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: _catalogHabits.length,
              itemBuilder: (context, index) {
                final habit = _catalogHabits[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCatalogHabitCard(habit),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 92)),
        ],
      ),
    );
  }

  Widget _buildCatalogSettingsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _buildGlassCard(
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showCatalogSettings = !_showCatalogSettings);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pengaturan default',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 240),
                    turns: _showCatalogSettings ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_formatRepeatPeriod(_repeatPeriod)} • ${_formatFrequency(_frequency)} • ${_currentColorName()} • $_icon',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  _buildRepeatPeriodSelector(),
                  const SizedBox(height: 14),
                  _buildFrequencySelector(),
                  if (_frequency == 'custom') ...[
                    const SizedBox(height: 14),
                    _buildCustomDaysPicker(),
                  ],
                  const SizedBox(height: 14),
                  _buildColorPicker(),
                  const SizedBox(height: 14),
                  _buildIconPicker(),
                ],
              ),
            ),
            crossFadeState: _showCatalogSettings
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogHabitCard(Habit habit) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _parseColor(_color);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _addCatalogHabit(habit),
      child: _buildGlassCard(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Text(_icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((habit.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      habit.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildInfoChip(_formatRepeatPeriod(_repeatPeriod)),
                      _buildInfoChip(_formatFrequency(_frequency)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCustomTab() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = _animationController.value;
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: _buildPreviewCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Form(key: _formKey, child: _buildFormCard()),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildScheduleCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildPersonalizationCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: _buildSubmitButton(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 86)),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _parseColor(_color);
    final title = _titleController.text.trim().isEmpty
        ? 'Nama habit kamu'
        : _titleController.text.trim();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(_icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatRepeatPeriod(_repeatPeriod)} • ${_formatFrequency(_frequency)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildSectionLabel('Informasi Habit', Icons.edit_note_rounded),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _titleController,
            label: 'Nama Habit',
            hint: 'Contoh: Baca Alkitab 15 menit',
            icon: Icons.edit_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama habit wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _descriptionController,
            label: 'Deskripsi (Opsional)',
            hint: 'Penjelasan singkat habit',
            icon: Icons.description_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _notesController,
            label: 'Catatan Pribadi (Opsional)',
            hint: 'Catatan tambahan untuk diri sendiri',
            icon: Icons.note_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Jadwal', Icons.schedule_rounded),
          const SizedBox(height: 12),
          _buildRepeatPeriodSelector(),
          const SizedBox(height: 14),
          _buildFrequencySelector(),
          if (_frequency == 'custom') ...[
            const SizedBox(height: 14),
            _buildCustomDaysPicker(),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalizationCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Personalisasi', Icons.palette_outlined),
          const SizedBox(height: 12),
          _buildColorPicker(),
          const SizedBox(height: 14),
          _buildIconPicker(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _createCustomHabit,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Buat Habit Baru'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatPeriodSelector() {
    return _buildSelectableGroup(
      title: 'Durasi Commit',
      selectedValue: _repeatPeriod,
      options: _repeatPeriodOptions,
      formatter: _formatRepeatPeriod,
      onChanged: (value) {
        HapticFeedback.lightImpact();
        setState(() => _repeatPeriod = value);
      },
    );
  }

  Widget _buildFrequencySelector() {
    return _buildSelectableGroup(
      title: 'Frekuensi',
      selectedValue: _frequency,
      options: _frequencyOptions,
      formatter: _formatFrequency,
      onChanged: (value) {
        HapticFeedback.lightImpact();
        setState(() {
          _frequency = value;
          if (value != 'custom') {
            _frequencyDays = [];
          }
        });
      },
    );
  }

  Widget _buildSelectableGroup({
    required String title,
    required String selectedValue,
    required List<String> options,
    required String Function(String value) formatter,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;

            return ChoiceChip(
              label: Text(formatter(option)),
              selected: isSelected,
              onSelected: (_) => onChanged(option),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.16),
              ),
              selectedColor: colorScheme.primary.withValues(alpha: 0.14),
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomDaysPicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Hari',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
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
                HapticFeedback.lightImpact();
                setState(() {
                  if (selected) {
                    _frequencyDays.add(index);
                    _frequencyDays.sort();
                  } else {
                    _frequencyDays.remove(index);
                  }
                });
              },
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.16),
              ),
              selectedColor: colorScheme.primary.withValues(alpha: 0.14),
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Warna',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _currentColorName(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _colorOptions.map((option) {
            final hex = option['hex']!;
            final color = _parseColor(hex);
            final isSelected = _color == hex;

            return InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _color = hex);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.onSurface
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIconPicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _parseColor(_color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ikon',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _currentIconName(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _iconOptions.map((option) {
            final emoji = option['emoji']!;
            final isSelected = _icon == emoji;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _icon = emoji);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? accent
                        : colorScheme.outline.withValues(alpha: 0.16),
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCenteredMessage({
    required IconData icon,
    required String message,
    String? subtitle,
    bool loading = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _buildGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                )
              else
                Icon(icon, size: 34, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    double radius = 18,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface.withValues(alpha: 0.92),
                colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
