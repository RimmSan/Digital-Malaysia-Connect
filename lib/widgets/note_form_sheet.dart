import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dashboard_note.dart';


Future<DashboardNote?> showNoteFormSheet(
    BuildContext context, {
      DashboardNote? existingNote,
      Set<String> existingTitles = const {},
    }) {
  return showModalBottomSheet<DashboardNote>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NoteFormSheet(
      existingNote: existingNote,
      existingTitles: existingTitles,
    ),
  );
}

class _NoteFormSheet extends StatefulWidget {
  final DashboardNote? existingNote;
  final Set<String> existingTitles;

  const _NoteFormSheet({
    this.existingNote,
    this.existingTitles = const {},
  });

  @override
  State<_NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends State<_NoteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _valueController;
  late TextEditingController _noteController;
  late String _category;

  bool get _isEditing => widget.existingNote != null;


  String? _validateTitle(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) return 'Title is required';
    if (trimmed.length < 3) return 'Title must be at least 3 characters';
    if (trimmed.length > 60) return 'Title must be 60 characters or fewer';
    if (!RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed)) {
      return 'Title must contain at least one letter or number';
    }
    if (widget.existingTitles.contains(trimmed.toLowerCase())) {
      return 'You already have an insight with this title';
    }
    return null;
  }

  String? _validateHighlightValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    if (trimmed.length > 24) return 'Keep this under 24 characters';

    final numberPart =
    trimmed.endsWith('%') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    final parsed = double.tryParse(numberPart);

    if (parsed == null) {
      return 'Numbers only, e.g. "95.4" or "95.4%"';
    }
    if (parsed < 0 || parsed > 1000) {
      return 'Value looks out of range';
    }

    return null;
  }

  String? _validateNote(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length > 500) return 'Note must be 500 characters or fewer';
    return null;
  }

  @override
  void initState() {
    super.initState();
    final n = widget.existingNote;
    _titleController = TextEditingController(text: n?.title ?? '');
    _valueController = TextEditingController(text: n?.highlightValue ?? '');
    _noteController = TextEditingController(text: n?.note ?? '');
    _category = n?.category ?? DashboardNote.categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final result = DashboardNote(
      id: widget.existingNote?.id ??
          now.microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      highlightValue: _valueController.text.trim().isEmpty
          ? null
          : _valueController.text.trim(),
      note: _noteController.text.trim(),
      createdAt: widget.existingNote?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                _isEditing ? 'Edit Insight' : 'New Insight',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Rural internet gap',
                  border: OutlineInputBorder(),
                ),
                maxLength: 60,
                validator: _validateTitle,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: DashboardNote.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Highlight value (optional)',
                  hintText: 'e.g. 95.4 or 95.4%',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.%]')),
                ],
                maxLength: 24,
                validator: _validateHighlightValue,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'What did you notice about this data?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLength: 500,
                validator: _validateNote,
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1E5A78),
                  ),
                  child: Text(_isEditing ? 'Save Changes' : 'Add Insight'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
