import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiChatInputWidget extends StatefulWidget {
  final Function(String query, List<String> attachments, String model, String effort) onSubmit;
  final List<String> suggestedQueries;
  final String? initialText;

  const AiChatInputWidget({
    super.key,
    required this.onSubmit,
    required this.suggestedQueries,
    this.initialText,
  });

  @override
  State<AiChatInputWidget> createState() => _AiChatInputWidgetState();
}

class _AiChatInputWidgetState extends State<AiChatInputWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  String _selectedModel = 'Qwen 2.5 (72B)';
  String _selectedEffort = 'Max Effort';

  final List<String> _models = [
    'Qwen 2.5 (72B)',
    'GPT 5.5',
    'Opus 4.8',
    'Composer 2.5',
    'Gemini 3.5 Flash',
  ];

  final List<String> _effortLevels = ['Low', 'Medium', 'Max Effort'];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cycleEffort() {
    int idx = _effortLevels.indexOf(_selectedEffort);
    int next = (idx + 1) % _effortLevels.length;
    setState(() {
      _selectedEffort = _effortLevels[next];
    });
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.onSubmit(text, [], _selectedModel, _selectedEffort);

    setState(() {
      _textController.clear();
    });
    _focusNode.unfocus();
  }

  void _selectQuickChip(String query) {
    // Strip bullet icon if present
    final cleanQ = query.replaceAll('✦', '').trim();
    _textController.text = cleanQ;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Action Chips Row (Only visible when suggestedQueries is non-empty)
        if (widget.suggestedQueries.isNotEmpty)
          Container(
            height: 32,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.suggestedQueries.length,
              itemBuilder: (context, index) {
                final q = widget.suggestedQueries[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => _selectQuickChip(q),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.sparkles, color: Color(0xFF38BDF8), size: 11),
                          const SizedBox(width: 5),
                          Text(
                            q,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Stable, Jitter-Free Native AI Chat Input Box
        Container(
          constraints: const BoxConstraints(minHeight: 52, maxHeight: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1322),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1E293B),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Text Field Entry
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 3,
                      minLines: 1,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12, height: 1.35),
                      decoration: InputDecoration(
                        hintText: 'Ask situational AI or query geospatial intelligence...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 2. Solid Control Toolbar
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Model Selector Pill (PopupMenu)
                          PopupMenuButton<String>(
                            onSelected: (model) {
                              setState(() {
                                _selectedModel = model;
                              });
                            },
                            color: const Color(0xFF0F172A),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF1E293B), width: 1),
                            ),
                            itemBuilder: (context) => _models.map((model) {
                              final isSelected = model == _selectedModel;
                              return PopupMenuItem<String>(
                                value: model,
                                height: 32,
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.sparkles,
                                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white38,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      model,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF162032),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3), width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.sparkles, color: Color(0xFF38BDF8), size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedModel,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: const Color(0xFF38BDF8),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(CupertinoIcons.chevron_down, color: Color(0xFF38BDF8), size: 9),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Effort Level Pill
                          InkWell(
                            onTap: _cycleEffort,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildEffortBars(_selectedEffort),
                                  const SizedBox(width: 5),
                                  Text(
                                    _selectedEffort,
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Circular 32x32 Electric Cyan Action Button
                  InkWell(
                    onTap: _submit,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.arrow_up, color: Colors.black, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffortBars(String effort) {
    int activeBars = effort == 'Low' ? 1 : (effort == 'Medium' ? 2 : 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        bool isActive = i < activeBars;
        return Container(
          width: 2.5,
          height: 6.0 + (i * 2.5),
          margin: const EdgeInsets.only(right: 1.5),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF10B981) : Colors.white24,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
