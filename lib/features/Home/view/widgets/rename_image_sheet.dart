import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/model/book_model.dart';
import 'package:image_app/features/Home/viewmodel/book_list_provider.dart';

class RenameBookSheet extends ConsumerStatefulWidget {
  final Book book;
  final String initialName;

  const RenameBookSheet({
    super.key,
    required this.book,
    required this.initialName,
  });

  @override
  ConsumerState<RenameBookSheet> createState() => _RenameBookSheetState();
}

class _RenameBookSheetState extends ConsumerState<RenameBookSheet> {
  late TextEditingController _nameController;
  bool _isNameValid = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isNameValid = _nameController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rename Book",
            style: TextStyle(
              fontSize: 24,
              fontWeight: .w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Book Name",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            onChanged: (value) => _validate(),
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Enter new Book name",
              hintStyle: const TextStyle(color: Colors.black45),
              errorText: !_isNameValid ? "Name cannot be blank" : null,
              filled: true,
              fillColor: CupertinoColors.systemGrey6,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isNameValid
                  ? () {
                      final newName = _nameController.text.trim();
                      ref
                          .read(bookListProvider.notifier)
                          .renameBook(widget.book, newName);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
