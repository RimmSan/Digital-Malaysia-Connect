import 'package:flutter/material.dart';

import '../models/intelligence_report.dart';
import '../services/intelligence_reports_service.dart';

enum ReportSortOption {
  newest,
  oldest,
  titleAZ,
  titleZA,
}

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

  List<IntelligenceReport> _reports = [];

  bool _isLoading = true;
  bool _isUpdating = false;

  ReportSortOption _sortOption = ReportSortOption.newest;

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

    try {
      final reports = await _reportsService.getAll();

      if (!mounted) return;

      setState(() {
        _reports = reports;
        _sortReports();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load saved reports.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  void _sortReports() {
    switch (_sortOption) {
      case ReportSortOption.newest:
        _reports.sort(
              (a, b) => b.updatedAt.compareTo(a.updatedAt),
        );
        break;

      case ReportSortOption.oldest:
        _reports.sort(
              (a, b) => a.updatedAt.compareTo(b.updatedAt),
        );
        break;

      case ReportSortOption.titleAZ:
        _reports.sort(
              (a, b) => a.title
              .toLowerCase()
              .compareTo(b.title.toLowerCase()),
        );
        break;

      case ReportSortOption.titleZA:
        _reports.sort(
              (a, b) => b.title
              .toLowerCase()
              .compareTo(a.title.toLowerCase()),
        );
        break;
    }
  }


  void _changeSort(ReportSortOption option) {
    setState(() {
      _sortOption = option;
      _sortReports();
    });
  }


  String _sortLabel(ReportSortOption option) {
    switch (option) {
      case ReportSortOption.newest:
        return 'Newest First';

      case ReportSortOption.oldest:
        return 'Oldest First';

      case ReportSortOption.titleAZ:
        return 'Title A-Z';

      case ReportSortOption.titleZA:
        return 'Title Z-A';
    }
  }


  String? _validateTitle(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Report title is required.';
    }

    if (trimmed.length < _minTitleLength) {
      return 'Title must be at least $_minTitleLength characters.';
    }

    if (trimmed.length > _maxTitleLength) {
      return 'Title cannot exceed $_maxTitleLength characters.';
    }

    return null;
  }


  String? _validateNote(String value) {
    final trimmed = value.trim();

    if (trimmed.length > _maxNoteLength) {
      return 'Note cannot exceed $_maxNoteLength characters.';
    }

    return null;
  }

  Future<void> _editReport(
      IntelligenceReport report,
      ) async {
    if (_isUpdating) return;

    final titleController = TextEditingController(
      text: report.title,
    );

    final noteController = TextEditingController(
      text: report.note,
    );

    String? titleError;
    String? noteError;

    final result = await showDialog<Map<String, String>>(
      context: context,
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
                      decoration: InputDecoration(
                        labelText: 'Report Title',
                        hintText:
                        '$_minTitleLength-$_maxTitleLength characters',
                        errorText: titleError,
                        border:
                        const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (titleError != null) {
                          setDialogState(() {
                            titleError = null;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: noteController,
                      maxLength: _maxNoteLength,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Personal Note',
                        hintText:
                        'Optional - maximum $_maxNoteLength characters',
                        errorText: noteError,
                        alignLabelWithHint: true,
                        border:
                        const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (noteError != null) {
                          setDialogState(() {
                            noteError = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton(
                  onPressed: () {
                    final title =
                    titleController.text.trim();

                    final note =
                    noteController.text.trim();

                    final newTitleError =
                    _validateTitle(title);

                    final newNoteError =
                    _validateNote(note);

                    if (newTitleError != null ||
                        newNoteError != null) {
                      setDialogState(() {
                        titleError = newTitleError;
                        noteError = newNoteError;
                      });

                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'title': title,
                        'note': note,
                      },
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    noteController.dispose();

    if (result == null) return;

    final newTitle = result['title']?.trim() ?? '';
    final newNote = result['note']?.trim() ?? '';

    final titleErrorCheck =
    _validateTitle(newTitle);

    final noteErrorCheck =
    _validateNote(newNote);

    if (titleErrorCheck != null ||
        noteErrorCheck != null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            titleErrorCheck ??
                noteErrorCheck ??
                'Invalid report input.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedReport = report.copyWith(
        title: newTitle,
        note: newNote,
        updatedAt: DateTime.now(),
      );

      await _reportsService.update(
        updatedReport,
      );

      if (!mounted) return;

      await _loadReports();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report updated successfully.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update report. Please try again.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }


  Future<void> _deleteReport(
      IntelligenceReport report,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Report',
          ),
          content: Text(
            'Are you sure you want to delete '
                '"${report.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _reportsService.delete(
        report.id,
      );

      if (!mounted) return;

      await _loadReports();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report deleted successfully.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete report. Please try again.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  Future<void> _viewReport(
      IntelligenceReport report,
      ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom:
              MediaQuery.of(sheetContext).viewInsets.bottom +
                  24,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEAF7FC,
                        ),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _reportIcon(report),
                        color: const Color(
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

                          const SizedBox(height: 3),

                          Text(
                            report.reportType,
                            style: TextStyle(
                              color:
                              Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _DetailRow(
                  label: 'Report Type',
                  value: report.reportType,
                ),

                _DetailRow(
                  label: 'State A',
                  value: report.stateA,
                ),

                if (report.stateB != null &&
                    report.stateB!.trim().isNotEmpty)
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
                    BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(
                        0xFFB6D5E1,
                      ),
                    ),
                  ),
                  child: Text(
                    report.insight,
                    style: const TextStyle(
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Personal Note',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  report.note.trim().isEmpty
                      ? 'No personal note added.'
                      : report.note,
                  style: TextStyle(
                    color:
                    report.note.trim().isEmpty
                        ? Colors.grey.shade600
                        : null,
                    height: 1.5,
                  ),
                ),

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
                    onPressed: () async {
                      Navigator.pop(
                        sheetContext,
                      );

                      await _editReport(
                        report,
                      );
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    label: const Text(
                      'Edit Report',
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _reportIcon(
      IntelligenceReport report,
      ) {
    if (report.reportType ==
        'State Comparison') {
      return Icons.compare_arrows_rounded;
    }

    return Icons.insights_outlined;
  }

  String _formatDateTime(DateTime date) {
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
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadReports,
        child: _reports.isEmpty
            ? _buildEmptyState()
            : _buildReportsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height:
          MediaQuery.of(context).size.height *
              0.16,
        ),

        Icon(
          Icons.bookmarks_outlined,
          size: 72,
          color: Colors.grey.shade400,
        ),

        const SizedBox(height: 18),

        const Text(
          'No Saved Reports Yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Save a State Growth Insight or '
              'State Comparison report and it '
              'will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReportsList() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment:
          CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Intelligence Reports',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${_reports.length} saved '
                        '${_reports.length == 1 ? 'report' : 'reports'}'
                        ' • Maximum 50',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<ReportSortOption>(
              tooltip: 'Sort Reports',
              initialValue: _sortOption,
              onSelected: _changeSort,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value:
                  ReportSortOption.newest,
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .arrow_downward_rounded,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text('Newest First'),
                    ],
                  ),
                ),

                const PopupMenuItem(
                  value:
                  ReportSortOption.oldest,
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .arrow_upward_rounded,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text('Oldest First'),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                const PopupMenuItem(
                  value:
                  ReportSortOption.titleAZ,
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text('Title A-Z'),
                    ],
                  ),
                ),

                const PopupMenuItem(
                  value:
                  ReportSortOption.titleZA,
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text('Title Z-A'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 19,
                    ),
                    SizedBox(width: 5),
                    Text('Sort'),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 16,
              color: Colors.grey.shade600,
            ),

            const SizedBox(width: 5),

            Text(
              'Sorted by: ${_sortLabel(_sortOption)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),


        ..._reports.map(
              (report) => Padding(
            padding:
            const EdgeInsets.only(
              bottom: 12,
            ),
            child: _buildReportCard(
              report,
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildReportCard(
      IntelligenceReport report,
      ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: () {
          _viewReport(report);
        },
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
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  _reportIcon(report),
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
                      report.reportType,
                      style: const TextStyle(
                        color:
                        Color(0xFF168AAD),
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      report.stateB == null ||
                          report.stateB!
                              .trim()
                              .isEmpty
                          ? report.stateA
                          : '${report.stateA} vs ${report.stateB}',
                      style: TextStyle(
                        color:
                        Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .schedule_outlined,
                          size: 14,
                          color:
                          Colors.grey.shade500,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            'Updated '
                                '${_formatDateTime(report.updatedAt)}',
                            style: TextStyle(
                              color:
                              Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                tooltip: 'Report Options',
                onSelected: (value) async {
                  switch (value) {
                    case 'view':
                      await _viewReport(
                        report,
                      );
                      break;

                    case 'edit':
                      await _editReport(
                        report,
                      );
                      break;

                    case 'delete':
                      await _deleteReport(
                        report,
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
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

                  const PopupMenuItem(
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

                  const PopupMenuDivider(),

                  const PopupMenuItem(
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
      padding:
      const EdgeInsets.only(
        bottom: 10,
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
                color: Colors.grey.shade600,
                fontWeight:
                FontWeight.w500,
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