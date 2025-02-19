class Soundboard {
  final String title;
  final String soundPath;

  const Soundboard({
    required this.title,
    required this.soundPath,
  });

  @override
  String toString() => 'Soundboard(title: $title, soundPath: $soundPath)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Soundboard &&
        other.title == title &&
        other.soundPath == soundPath;
  }

  @override
  int get hashCode => title.hashCode ^ soundPath.hashCode;
}
