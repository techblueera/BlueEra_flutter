/// A user-created chat sub-tab (a "list"/folder) that groups a hand-picked set
/// of conversations. Stored locally only — see [CustomChatTabController].
class CustomChatTab {
  final String id;
  String name;

  /// Conversation ids the user assigned to this tab.
  final List<String> conversationIds;

  CustomChatTab({
    required this.id,
    required this.name,
    List<String>? conversationIds,
  }) : conversationIds = conversationIds ?? <String>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'conversation_ids': conversationIds,
      };

  factory CustomChatTab.fromJson(Map<String, dynamic> json) => CustomChatTab(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        conversationIds: (json['conversation_ids'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
      );
}
