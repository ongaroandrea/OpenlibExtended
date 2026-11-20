import 'dart:async';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:openlib/features/eink/eink.dart' show BusyIndicator;

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:openlib/services/database.dart';
import 'package:openlib/services/library_book_details.dart';
import 'package:openlib/ui/components/book_info_widget.dart';
import 'package:openlib/ui/components/file_buttons_widget.dart';

final libraryBookDetailsProvider = Provider((ref) => LibraryBookDetails());

class BookPage extends ConsumerStatefulWidget {
  const BookPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<BookPage> createState() => _BookPageState();
}

class _BookPageState extends ConsumerState<BookPage> {
  late final Future<MyBook?> bookInfo;
  MyBook? _refreshedBook;

  @override
  void initState() {
    super.initState();
    bookInfo = _loadBook();
  }

  Future<MyBook?> _loadBook() async {
    final details = ref.read(libraryBookDetailsProvider);
    final book = await details.load(widget.id);
    if (book != null && mounted) unawaited(_refreshDescription(details, book));
    return book;
  }

  Future<void> _refreshDescription(
      LibraryBookDetails details, MyBook book) async {
    final updated = await details.refreshDescription(book);
    if (updated != null && mounted) {
      setState(() {
        _refreshedBook = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          return FutureBuilder(
              future: bookInfo,
              builder: (BuildContext context, AsyncSnapshot<MyBook?> snapshot) {
                if (snapshot.hasData) {
                  return BookInfoWidget(
                      data: _refreshedBook ?? snapshot.data,
                      child: FileOpenAndDeleteButtons(
                        id: snapshot.data!.id,
                        format: snapshot.data!.format!,
                        fileName: snapshot.data!.fileName,
                        onDelete: () {
                          Navigator.of(context).pop();
                        },
                      ));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.toString()),
                  );
                } else {
                  return Center(
                      child: SizedBox(
                    width: 25,
                    height: 25,
                    child: BusyIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ));
                }
              });
        },
      ),
    );
  }
}
