import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/investigation.dart';
import '../../models/world_event.dart';

class InvestigationDialog extends StatefulWidget {
  final WorldEvent? initialEvent;
  final Function(Investigation) onSave;

  const InvestigationDialog({
    super.key,
    this.initialEvent,
    required this.onSave,
  });

  @override
  State<InvestigationDialog> createState() => _InvestigationDialogState();
}

class _InvestigationDialogState extends State<InvestigationDialog> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final evTitle = widget.initialEvent?.title ?? 'Global Intelligence Investigation';
    _titleController = TextEditingController(text: 'Investigation: $evTitle');
    _notesController = TextEditingController(
      text: widget.initialEvent != null
          ? 'Investigating telemetry event ${widget.initialEvent!.id} (${widget.initialEvent!.type}) at lat ${widget.initialEvent!.latitude.toStringAsFixed(2)}°, lon ${widget.initialEvent!.longitude.toStringAsFixed(2)}°.'
          : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final inv = Investigation(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim().isEmpty ? 'Saved Investigation' : _titleController.text.trim(),
      notes: _notesController.text.trim(),
      eventIds: widget.initialEvent != null ? [widget.initialEvent!.id] : [],
      createdAt: DateTime.now(),
    );
    widget.onSave(inv);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1017),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.bookmark_fill, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'SAVE INVESTIGATION SESSION',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Text('SESSION TITLE', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 16),

              Text('ANALYST OBSERVATIONS & TELEMETRY NOTES', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 1),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: _submit,
                    child: Text('SAVE SESSION', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
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

