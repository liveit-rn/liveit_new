import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class HabitItem extends Equatable {
  final String id;
  final String name;
  final String? note;
  final bool checkedInToday;

  const HabitItem({
    required this.id,
    required this.name,
    this.note,
    this.checkedInToday = false,
  });

  HabitItem copyWith({bool? checkedInToday, String? note}) {
    return HabitItem(
      id: id,
      name: name,
      note: note ?? this.note,
      checkedInToday: checkedInToday ?? this.checkedInToday,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, note, checkedInToday];
}

@immutable
class DevotionalHighlight extends Equatable {
  final String title;
  final String snippet;
  final String? readingDuration;
  final bool isForToday;

  const DevotionalHighlight({
    required this.title,
    required this.snippet,
    this.readingDuration,
    this.isForToday = true,
  });

  @override
  List<Object?> get props => <Object?>[
    title,
    snippet,
    readingDuration,
    isForToday,
  ];
}

@immutable
class BadgeHighlight extends Equatable {
  final String name;
  final String reflection;

  const BadgeHighlight({required this.name, required this.reflection});

  @override
  List<Object?> get props => <Object?>[name, reflection];
}

@immutable
class GamificationHighlight extends Equatable {
  final int totalZoePoints;
  final String currentJourneyLevel;
  final int pointsToNextLevel;
  final BadgeHighlight? latestBadge;

  const GamificationHighlight({
    required this.totalZoePoints,
    required this.currentJourneyLevel,
    required this.pointsToNextLevel,
    this.latestBadge,
  });

  @override
  List<Object?> get props => <Object?>[
    totalZoePoints,
    currentJourneyLevel,
    pointsToNextLevel,
    latestBadge,
  ];
}

@immutable
class HabitRecommendation extends Equatable {
  final String id;
  final String name;
  final String description;

  const HabitRecommendation({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  List<Object?> get props => <Object?>[id, name, description];
}

@immutable
class HomeUiState extends Equatable {
  final String userFirstName;
  final List<HabitItem> pendingHabits;
  final List<HabitItem> completedHabits;
  final DevotionalHighlight? devotional;
  final GamificationHighlight gamification;
  final List<HabitRecommendation> recommendations;
  final bool isOffline;
  final bool hasError;

  const HomeUiState({
    required this.userFirstName,
    required this.pendingHabits,
    required this.completedHabits,
    required this.devotional,
    required this.gamification,
    required this.recommendations,
    this.isOffline = false,
    this.hasError = false,
  });

  int get completedCount => completedHabits.length;

  int get totalHabitCount => pendingHabits.length + completedHabits.length;

  bool get allHabitsDone => totalHabitCount > 0 && pendingHabits.isEmpty;

  bool get hasAnyHabit => totalHabitCount > 0;

  double get completionRate =>
      totalHabitCount == 0 ? 0 : completedCount / totalHabitCount;

  HomeUiState copyWith({
    String? userFirstName,
    List<HabitItem>? pendingHabits,
    List<HabitItem>? completedHabits,
    DevotionalHighlight? devotional,
    GamificationHighlight? gamification,
    List<HabitRecommendation>? recommendations,
    bool? isOffline,
    bool? hasError,
  }) {
    return HomeUiState(
      userFirstName: userFirstName ?? this.userFirstName,
      pendingHabits: pendingHabits ?? this.pendingHabits,
      completedHabits: completedHabits ?? this.completedHabits,
      devotional: devotional ?? this.devotional,
      gamification: gamification ?? this.gamification,
      recommendations: recommendations ?? this.recommendations,
      isOffline: isOffline ?? this.isOffline,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    userFirstName,
    pendingHabits.length,
    ...pendingHabits,
    completedHabits.length,
    ...completedHabits,
    devotional,
    gamification,
    recommendations.length,
    ...recommendations,
    isOffline,
    hasError,
  ];

  factory HomeUiState.sample() {
    return HomeUiState(
      userFirstName: 'Bagus',
      pendingHabits: const [
        HabitItem(
          id: 'habit-scripture',
          name: 'Baca Mazmur 23',
          note: 'Ambil 10 menit untuk merenungkan setiap ayat.',
        ),
        HabitItem(
          id: 'habit-prayer',
          name: 'Doa Syafaat',
          note: 'Fokus mendoakan mentor komunitas.',
        ),
        HabitItem(
          id: 'habit-gratitude',
          name: 'Jurnal Syukur',
          note: 'Catat 3 hal yang kamu syukuri hari ini.',
        ),
      ],
      completedHabits: const [
        HabitItem(
          id: 'habit-breath',
          name: '5-Minute Breath Prayer',
          note: 'Tarik napas, sebutkan “Tuhan hadir” setiap hembusan.',
          checkedInToday: true,
        ),
      ],
      devotional: const DevotionalHighlight(
        title: 'Berakar dalam Kasih-Nya',
        snippet:
            'Apa rasanya menjalani hari dengan kepastian bahwa kamu dicintai tanpa syarat? Renungan hari ini mengajakmu melangkah keluar dari rasa takut dan memilih percaya.',
        readingDuration: '4 menit baca',
        isForToday: true,
      ),
      gamification: const GamificationHighlight(
        totalZoePoints: 110,
        currentJourneyLevel: 'Langkah Pertama',
        pointsToNextLevel: 20,
        latestBadge: BadgeHighlight(
          name: 'First Step',
          reflection:
              'Nice! Kamu memulai hari ini dengan melibatkan Tuhan sejak pagi.',
        ),
      ),
      recommendations: const [
        HabitRecommendation(
          id: 'habit-morning',
          name: 'Morning Gratitude Stretch',
          description:
              'Mulai hari dengan peregangan ringan sambil menyebutkan 3 berkat.',
        ),
        HabitRecommendation(
          id: 'habit-evening',
          name: 'Evening Examen',
          description:
              'Luangkan 7 menit sebelum tidur untuk meninjau kehadiran Tuhan.',
        ),
        HabitRecommendation(
          id: 'habit-community',
          name: 'Check-in Komunitas',
          description:
              'Kirim pesan ke partner komunitasmu dan tanyakan kabar mereka.',
        ),
      ],
    );
  }
}
