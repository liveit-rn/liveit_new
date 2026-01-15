import 'package:flutter/material.dart';

typedef AssetUrlResolver = String? Function(String assetId);

class ProseMirrorRenderer extends StatelessWidget {
  final Map<String, dynamic> document;
  final AssetUrlResolver? resolveAssetUrl;

  const ProseMirrorRenderer({
    super.key,
    required this.document,
    this.resolveAssetUrl,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _readList(document['content']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final node in blocks) ...[_buildBlock(context, node)],
      ],
    );
  }

  Widget _buildBlock(
    BuildContext context,
    Map<String, dynamic> node, {
    bool tight = false,
  }) {
    final type = node['type'];

    if (type == 'heading') {
      final level = _readMap(node['attrs'])?['level'];
      final int headingLevel = level is int ? level : 2;
      final text = _buildInlineText(context, node);
      if (text.isEmpty) return const SizedBox.shrink();

      final textTheme = Theme.of(context).textTheme;
      final style = switch (headingLevel) {
        1 => textTheme.headlineMedium,
        2 => textTheme.headlineSmall,
        3 => textTheme.titleLarge,
        4 => textTheme.titleMedium,
        _ => textTheme.titleSmall,
      };

      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(
          text,
          style: style?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
        ),
      );
    }

    if (type == 'paragraph') {
      final spans = _buildInlineSpans(context, node);
      if (spans.isEmpty) {
        return SizedBox(height: tight ? 0 : 12);
      }

      return Padding(
        padding: EdgeInsets.only(bottom: tight ? 0 : 12),
        child: SelectableText.rich(
          TextSpan(children: spans),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
        ),
      );
    }

    if (type == 'bullet_list' || type == 'ordered_list') {
      final items = _readList(node['content']);
      if (items.isEmpty) return const SizedBox.shrink();

      final isOrdered = type == 'ordered_list';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              _buildListItem(
                context,
                items[i],
                index: isOrdered ? i + 1 : null,
              ),
          ],
        ),
      );
    }

    if (type == 'blockquote') {
      final children = _readList(node['content']);
      if (children.isEmpty) return const SizedBox.shrink();
      final colorScheme = Theme.of(context).colorScheme;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorScheme.outlineVariant, width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final child in children)
                  _buildBlock(context, child, tight: tight),
              ],
            ),
          ),
        ),
      );
    }

    if (type == 'horizontal_rule') {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1),
      );
    }

    if (type == 'image') {
      final attrs = _readMap(node['attrs']);
      final src = attrs?['src'];
      final assetId = attrs?['assetId'];

      String? url;
      if (src is String && src.isNotEmpty) {
        url = src;
      } else if (assetId is String && assetId.isNotEmpty) {
        url = resolveAssetUrl?.call(assetId);
      }

      if (url == null || url.isEmpty) return const SizedBox.shrink();

      final colorScheme = Theme.of(context).colorScheme;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 160,
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
      );
    }

    // Fallback: attempt to render child blocks if present.
    final children = _readList(node['content']);
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final child in children) _buildBlock(context, child, tight: tight),
      ],
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Map<String, dynamic> item, {
    required int? index,
  }) {
    final itemChildren = _readList(item['content']);
    if (itemChildren.isEmpty) return const SizedBox.shrink();

    final marker = index == null ? '•' : '$index.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(marker, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final child in itemChildren)
                  _buildBlock(context, child, tight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildInlineSpans(
    BuildContext context,
    Map<String, dynamic> node,
  ) {
    final children = _readList(node['content']);
    if (children.isEmpty) return const [];

    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final colorScheme = Theme.of(context).colorScheme;

    final spans = <TextSpan>[];
    for (final child in children) {
      final type = child['type'];
      if (type == 'text') {
        final text = child['text'];
        if (text is! String || text.isEmpty) continue;
        spans.add(
          TextSpan(
            text: text,
            style: _applyMarks(baseStyle, child['marks'], colorScheme),
          ),
        );
        continue;
      }

      if (type == 'hard_break') {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Unknown inline node - ignore.
    }

    return spans;
  }

  String _buildInlineText(BuildContext context, Map<String, dynamic> node) {
    final children = _readList(node['content']);
    if (children.isEmpty) return '';

    final buffer = StringBuffer();
    for (final child in children) {
      final type = child['type'];
      if (type == 'text') {
        final text = child['text'];
        if (text is String) buffer.write(text);
      } else if (type == 'hard_break') {
        buffer.write('\n');
      }
    }

    return buffer.toString().trim();
  }

  TextStyle? _applyMarks(
    TextStyle? baseStyle,
    Object? marks,
    ColorScheme colorScheme,
  ) {
    if (marks is! List) return baseStyle;

    TextStyle? style = baseStyle;
    for (final mark in marks) {
      if (mark is! Map<String, dynamic>) continue;
      final type = mark['type'];

      if (type == 'bold') {
        style = style?.copyWith(fontWeight: FontWeight.w700);
      } else if (type == 'italic') {
        style = style?.copyWith(fontStyle: FontStyle.italic);
      } else if (type == 'underline') {
        style = style?.copyWith(decoration: TextDecoration.underline);
      } else if (type == 'strike') {
        style = style?.copyWith(decoration: TextDecoration.lineThrough);
      } else if (type == 'link') {
        style = style?.copyWith(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        );
      }
    }

    return style;
  }

  static List<Map<String, dynamic>> _readList(Object? value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const [];
  }

  static Map<String, dynamic>? _readMap(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }
}
