import 'package:flutter/material.dart';
import 'shelf_tab.dart';
import 'cards_tab.dart';
import 'summary_tab.dart';

/// 珍藏 — Cherished Memory screen
/// Three sub-tabs: 书架 Shelf | 卡片 Cards | 总结 Summary
class CherishedMemoryScreen extends StatelessWidget {
  const CherishedMemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('珍藏'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.auto_stories), text: '书架'),
              Tab(icon: Icon(Icons.style), text: '卡片'),
              Tab(icon: Icon(Icons.bar_chart), text: '总结'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ShelfTab(),
            CardsTab(),
            SummaryTab(),
          ],
        ),
      ),
    );
  }
}
