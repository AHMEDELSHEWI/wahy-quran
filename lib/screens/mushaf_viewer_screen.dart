import 'package:flutter/material.dart';

/// Displays the mushaf as real page images (604 pages), matching the
/// printed Madinah mushaf layout with full tajweed color-coding.
///
/// Navigation: swipe left/right between pages, or jump directly via the
/// page-number field in the app bar. Surah/Juz/Hizb quick-jump is not
/// implemented yet — accurate start-page data for every surah still needs
/// verification against a trusted source before it ships (see README).
class MushafViewerScreen extends StatefulWidget {
  final int initialPage;
  const MushafViewerScreen({super.key, this.initialPage = 1});

  static const int totalPages = 604;

  @override
  State<MushafViewerScreen> createState() => _MushafViewerScreenState();
}

class _MushafViewerScreenState extends State<MushafViewerScreen> {
  late PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, MushafViewerScreen.totalPages);
    // Mushaf reads right-to-left, so page 1 is the last index in a
    // left-to-right PageController; we invert the index mapping instead
    // of fighting the controller's natural scroll direction.
    _controller = PageController(
      initialPage: MushafViewerScreen.totalPages - _currentPage,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _pageNumberForIndex(int index) => MushafViewerScreen.totalPages - index;

  int _indexForPageNumber(int pageNumber) =>
      MushafViewerScreen.totalPages - pageNumber;

  void _jumpToPage(int pageNumber) {
    final clamped = pageNumber.clamp(1, MushafViewerScreen.totalPages);
    _controller.jumpToPage(_indexForPageNumber(clamped));
    setState(() => _currentPage = clamped);
  }

  Future<void> _showJumpDialog() async {
    final textController = TextEditingController(text: '$_currentPage');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('انتقال إلى صفحة'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'رقم الصفحة (١ - ${MushafViewerScreen.totalPages})',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                final n = int.tryParse(textController.text.trim());
                Navigator.pop(context, n);
              },
              child: const Text('انتقال'),
            ),
          ],
        ),
      ),
    );
    if (result != null) _jumpToPage(result);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: GestureDetector(
            onTap: _showJumpDialog,
            child: Text(
              'صفحة $_currentPage من ${MushafViewerScreen.totalPages}',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.pageview_outlined),
              tooltip: 'انتقال إلى صفحة',
              onPressed: _showJumpDialog,
            ),
          ],
        ),
        body: PageView.builder(
          controller: _controller,
          itemCount: MushafViewerScreen.totalPages,
          onPageChanged: (index) {
            setState(() => _currentPage = _pageNumberForIndex(index));
          },
          itemBuilder: (context, index) {
            final pageNumber = _pageNumberForIndex(index);
            return InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.asset(
                  'assets/mushaf_pages/$pageNumber.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'تعذر تحميل صورة الصفحة $pageNumber',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
