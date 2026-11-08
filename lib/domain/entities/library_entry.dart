/// One title in the user's library (local SQLite, synced to Firebase
/// when signed in). Local SQLite is the source of truth.
class LibraryEntry {
  final int malId;
  final String status; // 'favorite', 'watching', 'plan', 'watched'
  final int lastEpisode;
  final int updatedAt; // epoch milliseconds, for last-write-wins sync

  const LibraryEntry({
    required this.malId,
    required this.status,
    this.lastEpisode = 0,
    required this.updatedAt,
  });

  bool get isFavorite => status == 'favorite';
  bool get isWatching => status == 'watching';
  bool get isPlan => status == 'plan';
  bool get isWatched => status == 'watched';

  LibraryEntry copyWith({String? status, int? lastEpisode, int? updatedAt}) =>
      LibraryEntry(
        malId: malId,
        status: status ?? this.status,
        lastEpisode: lastEpisode ?? this.lastEpisode,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        'mal_id': malId,
        'status': status,
        'last_episode': lastEpisode,
        'updated_at': updatedAt,
      };

  static LibraryEntry fromMap(Map<String, Object?> m) => LibraryEntry(
        malId: m['mal_id'] as int,
        status: (m['status'] as String?) ?? 'plan',
        lastEpisode: (m['last_episode'] as int?) ?? 0,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );
}

/// The four library statuses, in display order.
const List<String> libraryStatuses = ['favorite', 'watching', 'plan', 'watched'];
