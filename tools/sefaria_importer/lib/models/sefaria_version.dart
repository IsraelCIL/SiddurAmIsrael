/// Metadata for one version of a Sefaria text.
/// Returned by GET /api/versions/{ref} — does NOT include the full text body.
class SefariaVersion {
  const SefariaVersion({
    required this.versionTitle,
    required this.language,
    required this.versionSource,
    required this.priority,
  });

  factory SefariaVersion.fromJson(Map<String, dynamic> json) {
    return SefariaVersion(
      versionTitle: (json['versionTitle'] as String?) ?? '',
      language: (json['language'] as String?) ?? '',
      versionSource: (json['versionSource'] as String?) ?? '',
      priority: ((json['priority'] as num?)?.toInt()) ?? 0,
    );
  }

  final String versionTitle;
  final String language; // 'he' or 'en'
  final String versionSource;
  final int priority; // Sefaria's own ordering hint (higher = preferred)

  @override
  String toString() =>
      'SefariaVersion(title: "$versionTitle", lang: $language, priority: $priority)';
}
