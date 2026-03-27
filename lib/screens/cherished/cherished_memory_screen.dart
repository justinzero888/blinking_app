import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import 'shelf_tab.dart';
import 'cards_tab.dart';
import 'summary_tab.dart';

/// Keepsakes / 珍藏 — Cherished Memory screen
/// Three sub-tabs: 书架 Shelf | 卡片 Cards | 总结 Summary
class CherishedMemoryScreen extends StatelessWidget {
  const CherishedMemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isZh ? '珍藏' : 'Keepsakes'),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.auto_stories), text: isZh ? '书架' : 'Shelf'),
              Tab(icon: const Icon(Icons.style), text: isZh ? '卡片' : 'Cards'),
              Tab(icon: const Icon(Icons.bar_chart), text: isZh ? '总结' : 'Summary'),
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
