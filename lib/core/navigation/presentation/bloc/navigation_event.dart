part of 'navigation_bloc.dart';

// Events are handled by NavigationBloc
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationTabChanged extends NavigationEvent {
  const NavigationTabChanged(this.index);

  final int index;

  @override
  List<Object> get props => [index];
}
