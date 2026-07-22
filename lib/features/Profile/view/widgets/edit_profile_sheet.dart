import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/auth/viewmodel/auth_providers.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final String initialName;

  const EditProfileSheet({super.key, required this.initialName});

  @override
  ConsumerState<EditProfileSheet> createState() => EditProfileSheetState();
}

class EditProfileSheetState extends ConsumerState<EditProfileSheet> {
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
            "Edit Profile",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 32), // Increased spacing
          const Text(
            "Display Name",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10), // Spacing between label and input
          TextField(
            controller: _nameController,
            onChanged: (value) => _validate(),
            decoration: InputDecoration(
              hintText: "Enter your display name", // Changed from labelText
              hintStyle: const TextStyle(color: Colors.black45),
              errorText: !_isNameValid ? "Name cannot be blank" : null,
              filled: true,
              fillColor: CupertinoColors.systemGrey6,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 40), // Increased spacing before button
          SizedBox(
            width: double.infinity,
            height: 54, // Slightly taller button
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _isNameValid
                  ? () {
                      final newName = _nameController.text.trim();
                      ref.read(authControllerProvider.notifier).updateDisplayName(newName);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text(
                "Save",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16, // Slightly larger text
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}