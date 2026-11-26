/// Assistant screen for guided slot-filling chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/chat/chat_session.dart';
import 'package:ai_lesson_planner/core/chat/slot_filler.dart' as slot_filler;
import 'package:ai_lesson_planner/features/assistant/chat_bubble.dart';
import 'package:ai_lesson_planner/features/generator/generator_form_state.dart';
import 'package:ai_lesson_planner/features/generator/generator_screen.dart';
import 'package:ai_lesson_planner/features/plan_view/ilaw_plan_view.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart'
    show GradeInput, OutputLanguage, GenerationRequest;
import 'package:ai_lesson_planner/core/providers.dart';

/// Provider for the chat session state.
final chatSessionProvider = StateProvider<ChatSession>((ref) => ChatSession());

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;
  LessonPlan? _generatedPlan;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _focusTextField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final session = ref.read(chatSessionProvider);
      _controller.clear();

      // Add user message
      final updatedSession = session.addMessage(
        ChatMessage(role: 'user', content: text),
      );
      ref.read(chatSessionProvider.notifier).state = updatedSession;

      // Process message with SlotFiller
      final slotFillerInstance = ref.read(slotFillerProvider);
      final result = await slotFillerInstance.processMessage(
        text,
        updatedSession,
      );

      // Handle free-form lesson plan generation
      if (result.lessonPlanJson != null) {
        final plan = LessonPlan.fromJson(result.lessonPlanJson!);
        setState(() {
          _generatedPlan = plan;
        });

        // Add assistant response about the generated plan
        final assistantSession = updatedSession.addMessage(
          ChatMessage(role: 'assistant', content: result.assistantResponse),
        );
        ref.read(chatSessionProvider.notifier).state = assistantSession;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson plan generated! Tap to view or edit'),
          ),
        );
        _scrollToBottom();
        return;
      }

      // Apply patch to session
      var newSession = updatedSession;
      if (result.patch.isNotEmpty) {
        newSession = slot_filler.applyPatchToSession(
          updatedSession,
          result.patch,
        );
      }

      // Add assistant response
      final assistantSession = newSession.addMessage(
        ChatMessage(role: 'assistant', content: result.assistantResponse),
      );
      ref.read(chatSessionProvider.notifier).state = assistantSession;

      // Save to database
      await ref.read(chatRepositoryProvider).save(assistantSession);

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(chatSessionProvider);

    // Show the generated lesson plan in a dialog if available
    if (_generatedPlan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Generated Lesson Plan'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: IlawPlanView(plan: _generatedPlan!),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue Chat'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to edit mode with the generated plan
                  final request = GenerationRequest(
                    header: _generatedPlan!.header,
                    grades: _generatedPlan!.grades
                        .map(
                          (g) => GradeInput(
                            gradeLabel: g.gradeLabel,
                            male: g.learnersMale,
                            female: g.learnersFemale,
                            subTheme: g.subTheme,
                            competency: g.competencies.join('; '),
                          ),
                        )
                        .toList(),
                    sharedSubTheme: _generatedPlan!.sharedSubTheme,
                    language: _generatedPlan!.language == 'en'
                        ? OutputLanguage.english
                        : OutputLanguage.filipino,
                  );
                  final formState = GeneratorFormState.fromGenerationRequest(
                    request,
                  );
                  ref.read(generatorFormProvider.notifier).setState(formState);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GeneratorScreen()),
                  );
                },
                child: const Text('Edit in Form'),
              ),
            ],
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: session.messages.length,
              itemBuilder: (context, index) {
                final message = session.messages[index];
                return ChatBubble(
                  role: message.role,
                  content: message.content,
                  isMe: message.role == 'user',
                );
              },
            ),
          ),
          _buildSummaryCard(session),
        ],
      ),
      bottomNavigationBar: _buildInputBar(),
    );
  }

  Widget _buildSummaryCard(ChatSession session) {
    final canGenerate = session.canGenerate;
    final nextMissing = slot_filler.getNextMissingField(session);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Form so far', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'School',
              session.header.school,
              session.header.school.isEmpty ? 'tap to edit' : null,
            ),
            _buildSummaryRow(
              'Teacher',
              session.header.teacher,
              session.header.teacher.isEmpty ? 'tap to edit' : null,
            ),
            _buildSummaryRow(
              'Learning Area',
              session.header.learningArea,
              session.header.learningArea.isEmpty ? 'tap to edit' : null,
            ),
            if (nextMissing != 'all filled') ...[
              const SizedBox(height: 8),
              _buildQuickReplyChip(nextMissing),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canGenerate ? _openInForm : null,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        canGenerate
                            ? 'Generate from Chat'
                            : 'Complete Form First',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(String missingField) {
    String label;
    IconData icon;
    switch (missingField) {
      case 'school':
        label = 'Enter school name';
        icon = Icons.school;
      case 'teacher':
        label = 'Enter teacher name';
        icon = Icons.person;
      case 'learningArea':
        label = 'What subject?';
        icon = Icons.book;
      case 'date':
        label = 'Enter date';
        icon = Icons.calendar_today;
      case 'term':
        label = 'Enter term';
        icon = Icons.schedule;
      case 'sharedSubTheme':
        label = 'Enter sub-theme';
        icon = Icons.flag;
      case 'grades':
        label = 'What grades?';
        icon = Icons.numbers;
      case 'gradeLabel':
        label = 'Enter grade';
        icon = Icons.grade;
      default:
        label = 'Missing: $missingField';
        icon = Icons.help;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FilterChip(
        label: Text(label),
        avatar: Icon(icon, size: 18),
        onSelected: (_) {
          _focusTextField();
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, [String? hint]) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      subtitle: value.isEmpty || hint != null
          ? Text(
              hint ?? '',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            )
          : SelectableText(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
      trailing: value.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                // TODO: Show edit dialog for this field
              },
            )
          : null,
    );
  }

  void _openInForm() {
    final session = ref.read(chatSessionProvider);
    if (!session.canGenerate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields first'),
        ),
      );
      return;
    }

    // Pre-fill the generator form state from the chat session
    final request = session.toGenerationRequest();
    final formState = GeneratorFormState.fromGenerationRequest(request);

    // Use a provider to pass the pre-filled state
    ref.read(generatorFormProvider.notifier).setState(formState);

    // Navigate to the generator screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GeneratorScreen()));
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Describe your class...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
                minLines: 1,
                maxLines: 4,
                enabled: !_isProcessing,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _isProcessing ? null : _sendMessage,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
