part of 'navigation_bloc.dart';

// State for navigation tabs
class NavigationState extends Equatable {
  const NavigationState({this.currentIndex = 0});

  final int currentIndex;

  NavigationState copyWith({int? currentIndex}) {
    return NavigationState(currentIndex: currentIndex ?? this.currentIndex);
  }

  @override
  List<Object> get props => [currentIndex];
}
