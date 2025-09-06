import 'package:flutter/material.dart';

/// 성능 최적화된 리스트 뷰
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  // 성능 관련 설정
  final double? itemExtent; // 아이템 높이가 고정일 때 사용
  final int? itemCacheExtent; // 캐시할 아이템 수

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.itemExtent,
    this.itemCacheExtent,
  });

  @override
  Widget build(BuildContext context) {
    // 아이템이 적을 때는 Column 사용
    if (items.length < 20 && shrinkWrap) {
      return SingleChildScrollView(
        controller: controller,
        physics: physics,
        padding: padding,
        child: Column(
          children: items.asMap().entries.map((entry) {
            return itemBuilder(context, entry.value, entry.key);
          }).toList(),
        ),
      );
    }

    // 아이템이 많을 때는 ListView.builder 사용
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemExtent: itemExtent, // 성능 향상
      cacheExtent: itemCacheExtent?.toDouble(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

/// 페이지네이션을 지원하는 최적화된 리스트
class PaginatedListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) loadMore;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int itemsPerPage;

  const PaginatedListView({
    super.key,
    required this.loadMore,
    required this.itemBuilder,
    this.itemsPerPage = 20,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final newItems = await widget.loadMore(0);
      setState(() {
        _items.clear();
        _items.addAll(newItems);
        _currentPage = 1;
        _hasMore = newItems.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.loadMore(_currentPage);
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}
