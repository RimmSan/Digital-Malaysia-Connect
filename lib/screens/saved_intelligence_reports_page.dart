import 'package:flutter/material.dart';

import '../models/intelligence_report.dart';
import '../services/intelligence_reports_service.dart';

class SavedIntelligenceReportsPage extends StatefulWidget {
  const SavedIntelligenceReportsPage({super.key});

  @override
  State<SavedIntelligenceReportsPage> createState() =>
      _SavedIntelligenceReportsPageState();
}

class _SavedIntelligenceReportsPageState
    extends State<SavedIntelligenceReportsPage> {
  final IntelligenceReportsService _reportsService =
  IntelligenceReportsService();

  bool _isLoading = true;
  bool _isUpdating = false;

  List<IntelligenceReport> _reports = [];

  static const int _minTitleLength = 3;
  static const int _maxTitleLength = 60;
  static const int _maxNoteLength = 300;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    final reports = await _reportsService.getAll();

    reports.sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt),
    );

    if (!mounted) return;

    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  // ============================================================
  // VALIDATE REPORT TITLE
  // ============================================================

  String? _validateTitle(String value) {
    final title = value.trim();

    if (title.isEmpty) {
      return 'Report title is required.';
    }

    if (title.length < _minTitleLength) {
      return 'Title must be at least '
          '$_minTitleLength characters.';
    }

    if (title.length > _maxTitleLength) {
      return 'Title cannot exceed '
          '$_maxTitleLength characters.';
    }

    return null;
  }

  // ============================================================
  // VALIDATE PERSONAL NOTE
  // ============================================================

  String? _validateNote(String value) {
    final note = value.trim();

    if (note.length > _maxNoteLength) {
      return 'Personal note cannot exceed '
          '$_maxNoteLength characters.';
    }

    return null;
  }

  // ============================================================
  // EDIT REPORT
  // ============================================================

  Future<void> _editReport(
      IntelligenceReport report,
      ) async {
    final titleController = TextEditingController(
      text: report.title,
    );

    final noteController = TextEditingController(
      text: report.note,
    );

    String? titleError;
    String? noteError;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isUpdating,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Intelligence Report',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      maxLength: _maxTitleLength,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Report Title',
                        hintText:
                        '$_minTitleLength-$_maxTitleLength characters',
                        prefixIcon: const Icon(
                          Icons.title_outlined,
                        ),
                        border: const OutlineInputBorder(),
                        errorText: titleError,
                      ),
                      onChanged: (value) {
                        if (titleError != null) {
                          setDialogState(() {
                            titleError = _validateTitle(
                              value,
                            );
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      maxLength: _maxNoteLength,
                      decoration: InputDecoration(
                        labelText: 'Personal Note',
                        hintText:
                        'Optional - maximum $_maxNoteLength characters',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(
                          Icons.notes_outlined,
                        ),
                        border: const OutlineInputBorder(),
                        errorText: noteError,
                      ),
                      onChanged: (value) {
                        if (noteError != null) {
                          setDialogState(() {
                            noteError = _validateNote(
                              value,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isUpdating
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton(
                  onPressed: _isUpdating
                      ? null
                      : () {
                    final titleValidation =
                    _validateTitle(
                      titleController.text,
                    );

                    final noteValidation =
                    _validateNote(
                      noteController.text,
                    );

                    if (titleValidation != null ||
                        noteValidation != null) {
                      setDialogState(() {
                        titleError = titleValidation;
                        noteError = noteValidation;
                      });

                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child: const Text(
                    'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      titleController.dispose();
      noteController.dispose();
      return;
    }

    if (_isUpdating) {
      titleController.dispose();
      noteController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final note = noteController.text.trim();

    // Defensive validation before saving.
    final titleValidation = _validateTitle(title);
    final noteValidation = _validateNote(note);

    if (titleValidation != null ||
        noteValidation != null) {
      titleController.dispose();
      noteController.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            titleValidation ??
                noteValidation ??
                'Invalid report information.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedReport = report.copyWith(
        title: title,
        note: note,

        // createdAt is intentionally NOT changed.
        // Only updatedAt changes when editing.
        updatedAt: DateTime.now(),
      );

      await _reportsService.update(
        updatedReport,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report updated successfully.',
          ),
        ),
      );

      await _loadReports();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update report. Please try again.',
          ),
        ),
      );
    } finally {
      titleController.dispose();
      noteController.dispose();

      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE REPORT
  // ============================================================

  Future<void> _deleteReport(
      IntelligenceReport report,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          title: const Text(
            'Delete Report?',
          ),
          content: Text(
            'Are you sure you want to delete "${report.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _reportsService.delete(
      report.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Report deleted successfully.',
        ),
      ),
    );

    await _loadReports();
  }

  // ============================================================
  // VIEW REPORT
  // ============================================================

  void _viewReport(
      IntelligenceReport report,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 +
                  MediaQuery.of(context)
                      .viewInsets
                      .bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEAF7FC,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: const Icon(
                          Icons.insights_outlined,
                          color: Color(
                            0xFF168AAD,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            Text(
                              report.reportType,
                              style: TextStyle(
                                color: Colors
                                    .grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _DetailRow(
                    label: 'State A',
                    value: report.stateA,
                  ),

                  if (report.stateB != null &&
                      report.stateB!
                          .trim()
                          .isNotEmpty)
                    _DetailRow(
                      label: 'State B',
                      value: report.stateB!,
                    ),

                  const SizedBox(height: 18),

                  const Text(
                    'Generated Insight',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFEAF7FC,
                      ),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Text(
                      report.insight,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ),

                  if (report.note
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 18),

                    const Text(
                      'Personal Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .cardColor,
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                        border: Border.all(
                          color: Colors.grey
                              .withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        report.note,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  _DetailRow(
                    label: 'Created',
                    value: _formatDateTime(
                      report.createdAt,
                    ),
                  ),

                  _DetailRow(
                    label: 'Last Updated',
                    value: _formatDateTime(
                      report.updatedAt,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);

                        _editReport(report);
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                      label: const Text(
                        'Edit Report',
                      ),
                      style:
                      FilledButton.styleFrom(
                        backgroundColor:
                        const Color(
                          0xFF168AAD,
                        ),
                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(
      DateTime date,
      ) {
    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final hour =
    date.hour.toString().padLeft(2, '0');

    final minute =
    date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  String _getStatesText(
      IntelligenceReport report,
      ) {
    if (report.stateB == null ||
        report.stateB!.trim().isEmpty) {
      return report.stateA;
    }

    return '${report.stateA} ↔ ${report.stateB}';
  }

  IconData _getReportIcon(
      IntelligenceReport report,
      ) {
    if (report.reportType ==
        'State Comparison') {
      return Icons.compare_arrows_rounded;
    }

    return Icons.trending_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Intelligence Reports',
        ),
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadReports,
        child: _reports.isEmpty
            ? ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(
            24,
          ),
          children: const [
            SizedBox(height: 100),

            Icon(
              Icons
                  .bookmark_border_rounded,
              size: 70,
              color: Colors.grey,
            ),

            SizedBox(height: 18),

            Text(
              'No Saved Reports Yet',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Generate a state insight or comparison and save it here for later.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        )
            : ListView(
          padding:
          const EdgeInsets.all(
            16,
          ),
          children: [
            const Text(
              'Your Intelligence Reports',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${_reports.length} saved report${_reports.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors
                    .grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            ..._reports.map(
                  (report) =>
                  _ReportCard(
                    report: report,
                    stateText:
                    _getStatesText(
                      report,
                    ),
                    icon:
                    _getReportIcon(
                      report,
                    ),
                    dateText:
                    _formatDateTime(
                      report.updatedAt,
                    ),
                    onView: () {
                      _viewReport(
                        report,
                      );
                    },
                    onEdit: () {
                      _editReport(
                        report,
                      );
                    },
                    onDelete: () {
                      _deleteReport(
                        report,
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// REPORT CARD
// ============================================================

class _ReportCard extends StatelessWidget {
  final IntelligenceReport report;

  final String stateText;
  final String dateText;

  final IconData icon;

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.stateText,
    required this.dateText,
    required this.icon,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF7FC,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(
                    0xFF168AAD,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      stateText,
                      style: const TextStyle(
                        color:
                        Color(0xFF168AAD),
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .schedule_outlined,
                          size: 14,
                          color: Colors
                              .grey.shade500,
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Text(
                          dateText,
                          style: TextStyle(
                            color: Colors
                                .grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                      BoxDecoration(
                        color: const Color(
                          0xFFEAF7FC,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        report.reportType,
                        style:
                        const TextStyle(
                          color: Color(
                            0xFF075985,
                          ),
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    onView();
                  }

                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder:
                    (context) => const [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .visibility_outlined,
                        ),
                        SizedBox(width: 10),
                        Text('View'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                        ),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color:
                Colors.grey.shade600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}