import 'package:flutter/material.dart';
import '../models/dashboard_note.dart';

// ============================================================
// NOTE FORM SHEET
// ------------------------------------------------------------
// Bottom sheet used for both CREATE (existingNote == null) and
// UPDATE (existingNote != null). Returns a DashboardNote via
// Navigator.pop when saved, or null if cancelled.
// ============================================================

Future<DashboardNote?> showNoteFormSheet(
    BuildContext context, {
      DashboardNote? existingNote,
    }) {
  return showModalBottomSheet<DashboardNote>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NoteFormSheet(existingNote: existingNote),
  );
}

class _NoteFormSheet extends StatefulWidget {
  final DashboardNote? existingNote;

  const _NoteFormSheet({this.existingNote});

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
                  counterText: '',
                ),
                maxLength: 60,
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Title is required';
                  if (trimmed.length > 60) return 'Title is too long';
                  return null;
                },
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
                  hintText: 'e.g. 95.4% or Selangor',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 24,
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
