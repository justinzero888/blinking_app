import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/entry_provider.dart';
import '../../providers/tag_provider.dart';
import '../../models/models.dart';
import '../add_entry_screen.dart';
import '../cherished/card_builder_dialog.dart';

class MomentScreen extends StatefulWidget {
  const MomentScreen({super.key});

  @override
  State<MomentScreen> createState() => _MomentScreenState();
}

class _MomentScreenState extends State<MomentScreen> {
  String _filter = 'all'; // all, today, week, tag
  String _searchQuery = '';
  String? _tagFilterId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('瞬间', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<EntryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索记录...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                ),
              ),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('全部', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('今天', 'today'),
                    const SizedBox(width: 8),
                    _buildFilterChip('本周', 'week'),
                    const SizedBox(width: 8),
                    _buildFilterChip('标签', 'tag'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Entry List
              Expanded(
                child: _buildEntryList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (value == 'tag') {
          if (selected) {
            _showTagPicker();
          } else {
            setState(() {
              _filter = 'all';
              _tagFilterId = null;
            });
          }
        } else {
          setState(() {
            _filter = value;
            _tagFilterId = null;
          });
        }
      },
    );
  }

  void _showTagPicker() {
    final tagProvider = context.read<TagProvider>();
    final tags = tagProvider.tags;

    if (tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无标签，请先在设置中添加标签')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择标签'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: tags.map((tag) {
              final colorValue =
                  int.parse(tag.color.substring(1), radix: 16) + 0xFF000000;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(colorValue),
                  radius: 8,
                ),
                title: Text(tag.name),
                onTap: () {
                  setState(() {
                    _filter = 'tag';
                    _tagFilterId = tag.id;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filter = 'all';
                _tagFilterId = null;
              });
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(EntryProvider provider) {
    final now = DateTime.now();

    // Get base list from date filter
    List<Entry> entries;
    switch (_filter) {
      case 'today':
        entries = provider.allEntries.where((e) =>
            e.createdAt.year == now.year &&
            e.createdAt.month == now.month &&
            e.createdAt.day == now.day).toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        entries = provider.allEntries.where((e) => e.createdAt.isAfter(weekAgo)).toList();
        break;
      case 'tag':
        entries = _tagFilterId != null
            ? provider.allEntries.where((e) => e.tagIds.contains(_tagFilterId)).toList()
            : provider.allEntries;
        break;
      default:
        entries = provider.allEntries;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      entries = entries
          .where((e) => e.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (entries.isEmpty) {
      return const Center(
        child: Text('暂无记录\n点击 + 添加第一条', textAlign: TextAlign.center),
      );
    }

    // Group by date
    final grouped = <String, List<Entry>>{};
    for (var entry in entries) {
      final dateKey = DateFormat('yyyy年M月d日').format(entry.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dateEntries = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _isToday(dateEntries.first.createdAt) ? '今天' : dateKey,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ...dateEntries.map((entry) => _buildEntryCard(entry, provider)),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(Entry entry, EntryProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getEntryIcon(entry.type),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(entry.content),
        subtitle: Text(
          DateFormat('HH:mm').format(entry.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.tagIds.isNotEmpty) ...[
              const Icon(Icons.label, size: 16, color: Colors.grey),
              const SizedBox(width: 2),
              Text('${entry.tagIds.length}',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            IconButton(
              icon: const Icon(Icons.style_outlined, size: 18, color: Colors.grey),
              tooltip: '制作卡片',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardBuilderDialog(initialEntry: entry),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEntryScreen(existingEntry: entry),
            ),
          );
        },
        onLongPress: () {
          _showDeleteDialog(entry, provider);
        },
      ),
    );
  }

  IconData _getEntryIcon(EntryType type) {
    switch (type) {
      case EntryType.routine:
        return Icons.check_circle;
      case EntryType.freeform:
        return Icons.note;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showDeleteDialog(Entry entry, EntryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteEntry(entry.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
