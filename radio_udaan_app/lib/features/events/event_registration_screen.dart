import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/storage/registration_draft_storage.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/udaan_text_styles.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import '../shell/main_shell_screen.dart';
import 'models/form_schema.dart';
import 'registration_account_prefill.dart';
import 'widgets/registration_form_styles.dart';

/// Server-driven Forminator registration for a single event.
final eventFormProvider =
    FutureProvider.family<FormSchema, int>((ref, eventId) async {
  return ref.read(radioudaanApiProvider).getEventForm(eventId);
});

class EventRegistrationScreen extends ConsumerStatefulWidget {
  const EventRegistrationScreen({
    required this.eventId,
    required this.title,
    super.key,
  });

  final int eventId;
  final String title;

  @override
  ConsumerState<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState
    extends ConsumerState<EventRegistrationScreen> {
  final _values = <String, dynamic>{};
  final _uploadLabels = <String, String>{};
  final _uploadProgress = <String, double>{};
  final _uploadErrors = <String, String>{};
  final _pendingUploads = <String, ({String path, String name})>{};
  final _fieldKeys = <String, GlobalKey>{};
  final _textControllers = <String, TextEditingController>{};
  final _scrollController = ScrollController();
  String? _error;
  String? _success;
  String? _validationFieldKey;
  String? _validationMessage;
  bool _submitting = false;
  bool _draftLoaded = false;
  bool _accountDefaultsApplied = false;
  bool _unsupportedAnnounced = false;
  final _uploadAnnouncedMilestones = <String, int>{};
  Timer? _draftSaveDebounce;

  AppCopy get _copy => ref.read(appCopyProvider);

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    _draftSaveDebounce?.cancel();
    _scrollController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _textControllerFor(FormFieldSchema field) {
    return _textControllers.putIfAbsent(field.key, () {
      final text = displayValueForField(field, _values[field.key]);
      return TextEditingController(text: text);
    });
  }

  void _syncTextController(FormFieldSchema field) {
    final controller = _textControllers[field.key];
    if (controller == null) return;
    final text = displayValueForField(field, _values[field.key]);
    if (controller.text != text) {
      controller.text = text;
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final storage = await RegistrationDraftStorage.create();
      final draft = await storage.load(widget.eventId);
      if (!mounted) return;
      if (draft != null) {
        setState(() {
          _values.addAll(draft.values);
          _uploadLabels.addAll(draft.uploadLabels);
        });
      }
    } finally {
      if (mounted) setState(() => _draftLoaded = true);
    }
  }

  void _scheduleDraftSave() {
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_persistDraft());
    });
  }

  Future<void> _persistDraft() async {
    try {
      final storage = await RegistrationDraftStorage.create();
      await storage.save(
        eventId: widget.eventId,
        values: _values,
        uploadLabels: _uploadLabels,
      );
    } catch (_) {
      // Draft save is best-effort; ignore storage failures.
    }
  }

  Future<void> _clearDraft() async {
    try {
      final storage = await RegistrationDraftStorage.create();
      await storage.clear(widget.eventId);
    } catch (_) {}
  }

  void _announce(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  String _requiredMessage(FormFieldSchema field) =>
      '${registrationFieldDisplayLabel(field.label)}. '
      '${_copy.registrationFieldRequired}';

  bool _isRequiredValueMissing(FormFieldSchema field) {
    if (!field.required) return false;
    final raw = _values[field.key];
    switch (field.type) {
      case 'checkbox':
        if (field.options.length > 1) {
          if (raw is List) return raw.isEmpty;
          return true;
        }
        return raw != true && raw != '1';
      case 'upload':
        return raw == null || raw.toString().trim().isEmpty;
      default:
        return raw == null || raw.toString().trim().isEmpty;
    }
  }

  FormFieldSchema? _firstInvalidField(FormSchema schema) {
    final bySection = <String, List<FormFieldSchema>>{};
    for (final f in schema.fields) {
      bySection.putIfAbsent(f.sectionId, () => []).add(f);
    }
    for (final section in schema.sections) {
      final fields = bySection[section.id];
      if (fields == null) continue;
      for (final field in fields) {
        if (_isRequiredValueMissing(field)) return field;
      }
    }
    return null;
  }

  void _scrollToField(String key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _fieldKeys[key]?.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    });
  }

  void _setFieldValue(String key, dynamic value, {bool rebuild = true}) {
    _values[key] = value;
    final clearingValidation = _validationFieldKey == key;
    if (rebuild || clearingValidation) {
      setState(() {
        if (clearingValidation) {
          _validationFieldKey = null;
          _validationMessage = null;
        }
      });
    }
    _scheduleDraftSave();
  }

  void _onTextFieldChanged(FormFieldSchema field, String value) {
    _values[field.key] = value;
    if (_validationFieldKey == field.key) {
      setState(() {
        _validationFieldKey = null;
        _validationMessage = null;
      });
    }
    _scheduleDraftSave();
  }

  void _applyAccountDefaults(FormSchema schema) {
    final user = ref.read(authUserProvider);
    if (user == null || !mounted) return;

    var changed = false;
    for (final field in schema.fields) {
      final accountValue = accountValueForField(field, user);
      if (accountValue != null) {
        final existing = _values[field.key]?.toString().trim() ?? '';
        if (existing.isEmpty) {
          _values[field.key] = accountValue;
          changed = true;
        }
      }
    }
    if (changed) {
      for (final field in schema.fields) {
        if (_values.containsKey(field.key)) {
          _syncTextController(field);
        }
      }
    }
    if (changed && mounted) setState(() {});
  }

  String _fieldSemanticsLabel(FormFieldSchema field) {
    final clean = registrationFieldDisplayLabel(field.label);
    return field.required ? '$clean, required' : clean;
  }

  bool _isAccountLockedField(FormFieldSchema field) {
    final user = ref.read(authUserProvider);
    if (user == null) return false;
    return accountValueForField(field, user) != null;
  }

  void _announceUploadMilestone(FormFieldSchema field, double progress) {
    final percent = (progress * 100).round().clamp(0, 100);
    final uploadLabel = registrationFieldDisplayLabel(field.label);
    for (final milestone in const [25, 50, 75, 100]) {
      if (percent >= milestone &&
          (_uploadAnnouncedMilestones[field.key] ?? 0) < milestone) {
        _uploadAnnouncedMilestones[field.key] = milestone;
        _announce(
          _copy.registrationUploadProgressLabel(uploadLabel, milestone),
        );
        break;
      }
    }
  }

  InputDecoration _fieldDecoration(
    BuildContext context,
    FormFieldSchema field,
  ) {
    return registrationFieldDecoration(
      context,
      hint: field.placeholder,
      errorText:
          _validationFieldKey == field.key ? _validationMessage : null,
    );
  }

  Widget _fieldShell(
    BuildContext context,
    FormFieldSchema field,
    Widget child, {
    bool errorOnDecoration = false,
  }) {
    final anchorKey = _fieldKeys.putIfAbsent(field.key, () => GlobalKey());
    final showBelow = !errorOnDecoration && _validationFieldKey == field.key;
    final labelText = registrationFieldLabelText(field);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        key: anchorKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (labelText.isNotEmpty)
            Text(
              labelText,
              style: registrationFieldLabelStyle(
                context,
                required: field.required,
              ),
            ),
          if (labelText.isNotEmpty) const SizedBox(height: 8),
          child,
          if (showBelow && _validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Semantics(
                label: _validationMessage,
                liveRegion: true,
                child: Text(
                  _validationMessage!,
                  style: udaanTextStyle(
                    context,
                    fontSize: 14,
                    color: context.udaan.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _textField({
    required BuildContext context,
    required FormFieldSchema field,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? hintOverride,
  }) {
    final controller = _textControllerFor(field);
    final isAccountLocked = _isAccountLockedField(field);
    final palette = context.udaan;

    return _fieldShell(
      context,
      field,
      Semantics(
        label: _fieldSemanticsLabel(field),
        hint: isAccountLocked
            ? _copy.registrationAccountLockedHint
            : (hintOverride ?? field.placeholder),
        textField: true,
        readOnly: isAccountLocked,
        child: TextFormField(
          controller: controller,
          readOnly: isAccountLocked,
          style: registrationFieldInputStyle(
            context,
            readOnly: isAccountLocked,
          ),
          decoration: _fieldDecoration(context, field).copyWith(
            hintText: hintOverride ?? field.placeholder,
            suffixIcon: isAccountLocked
                ? Icon(
                    Icons.lock_outline,
                    color: palette.onSurfaceVariant,
                  )
                : null,
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          onChanged: isAccountLocked ? null : (v) => _onTextFieldChanged(field, v),
        ),
      ),
      errorOnDecoration: true,
    );
  }

  static final _apiDateFormat = DateFormat('yyyy-MM-dd');
  static final _apiTimeFormat = DateFormat('HH:mm');
  static final _apiDateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  String? _displayValue(FormFieldSchema field) {
    final raw = _values[field.key];
    if (raw == null || raw.toString().isEmpty) return null;
    switch (field.type) {
      case 'date':
        final parsed = DateTime.tryParse(raw.toString());
        return parsed != null
            ? MaterialLocalizations.of(context).formatFullDate(parsed)
            : raw.toString();
      case 'time':
        final parts = raw.toString().split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          return TimeOfDay(hour: hour, minute: minute).format(context);
        }
        return raw.toString();
      case 'datetime':
        final parsed = DateTime.tryParse(raw.toString().replaceFirst(' ', 'T'));
        return parsed != null
            ? '${MaterialLocalizations.of(context).formatFullDate(parsed)} '
                '${TimeOfDay.fromDateTime(parsed).format(context)}'
            : raw.toString();
      default:
        return raw.toString();
    }
  }

  Future<void> _pickDate(FormFieldSchema field) async {
    final initial = DateTime.tryParse(_values[field.key]?.toString() ?? '') ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: field.label,
    );
    if (picked == null || !mounted) return;
    _setFieldValue(field.key, _apiDateFormat.format(picked));
  }

  Future<void> _pickTime(FormFieldSchema field) async {
    final raw = _values[field.key]?.toString();
    TimeOfDay initial = TimeOfDay.now();
    if (raw != null && raw.contains(':')) {
      final parts = raw.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? initial.hour,
        minute: int.tryParse(parts[1]) ?? initial.minute,
      );
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: field.label,
    );
    if (picked == null || !mounted) return;
    final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
    _setFieldValue(field.key, _apiTimeFormat.format(dt));
  }

  Future<void> _pickDateTime(FormFieldSchema field) async {
    final existing = _values[field.key]?.toString().replaceFirst(' ', 'T');
    final initial = DateTime.tryParse(existing ?? '') ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: field.label,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: field.label,
    );
    if (time == null || !mounted) return;
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _setFieldValue(field.key, _apiDateTimeFormat.format(combined));
  }

  Widget _pickerField({
    required BuildContext context,
    required FormFieldSchema field,
    required Future<void> Function(FormFieldSchema field) onPick,
    required String hint,
    required IconData icon,
  }) {
    final display = _displayValue(field);
    final theme = Theme.of(context);
    return _fieldShell(
      context,
      field,
      Semantics(
          label: _fieldSemanticsLabel(field),
          hint: hint,
          value: display,
          button: true,
          child: InkWell(
            onTap: () => onPick(field),
            child: InputDecorator(
              decoration: _fieldDecoration(context, field).copyWith(
                suffixIcon: Icon(icon),
              ),
              child: Text(
                display ?? hint,
                style: display == null
                    ? theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor,
                      )
                    : theme.textTheme.bodyLarge,
              ),
            ),
          ),
      ),
      errorOnDecoration: true,
    );
  }

  Future<void> _uploadPickedFile(
    FormFieldSchema field, {
    required String path,
    required String name,
  }) async {
    setState(() {
      _error = null;
      _uploadErrors.remove(field.key);
      _uploadProgress[field.key] = 0;
      _uploadAnnouncedMilestones.remove(field.key);
      if (_validationFieldKey == field.key) {
        _validationFieldKey = null;
        _validationMessage = null;
      }
    });

    try {
      final uploaded = await ref.read(radioudaanApiProvider).uploadFile(
            eventId: widget.eventId,
            fieldKey: field.key,
            filePath: path,
            fileName: name,
            onSendProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              final progress = sent / total;
              setState(() => _uploadProgress[field.key] = progress);
              _announceUploadMilestone(field, progress);
            },
          );
      if (!mounted) return;
      setState(() {
        _values[field.key] = uploaded.uploadId;
        _uploadLabels[field.key] = uploaded.fileName;
        _uploadProgress.remove(field.key);
        _uploadAnnouncedMilestones.remove(field.key);
        _uploadErrors.remove(field.key);
        _pendingUploads.remove(field.key);
      });
      _scheduleDraftSave();
      _announce('${uploaded.fileName} selected for ${field.label}');
    } catch (e) {
      if (!mounted) return;
      final message = parseApiError(e).message;
      setState(() {
        _uploadProgress.remove(field.key);
        _uploadAnnouncedMilestones.remove(field.key);
        _uploadErrors[field.key] = message;
      });
      _announce('${field.label}. $message');
    }
  }

  Future<void> _pickFile(FormFieldSchema field, FormSchema schema) async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null) return;

    _pendingUploads[field.key] = (path: file.path!, name: file.name);
    await _uploadPickedFile(field, path: file.path!, name: file.name);
  }

  Future<void> _retryUpload(FormFieldSchema field, FormSchema schema) async {
    final pending = _pendingUploads[field.key];
    if (pending == null) {
      await _pickFile(field, schema);
      return;
    }
    await _uploadPickedFile(
      field,
      path: pending.path,
      name: pending.name,
    );
  }

  Future<void> _submit(FormSchema schema) async {
    final invalid = _firstInvalidField(schema);
    if (invalid != null) {
      final message = _requiredMessage(invalid);
      setState(() {
        _error = null;
        _success = null;
        _validationFieldKey = invalid.key;
        _validationMessage = message;
      });
      _announce(message);
      _scrollToField(invalid.key);
      return;
    }

    setState(() {
      _error = null;
      _success = null;
      _validationFieldKey = null;
      _validationMessage = null;
      _submitting = true;
    });

    try {
      final result = await ref.read(radioudaanApiProvider).submitRegistration(
            eventId: widget.eventId,
            payload: Map<String, dynamic>.from(_values),
          );
      final prefix = ref.read(appCopyProvider).registrationSuccessPrefix;
      await _clearDraft();
      final successMessage = '$prefix ${result.entryId}.';
      setState(() {
        _values.clear();
        _uploadLabels.clear();
        _pendingUploads.clear();
        _success = successMessage;
        for (final controller in _textControllers.values) {
          controller.clear();
        }
      });
      _announce(successMessage);
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
      _announce(message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openProfileTab() {
    Navigator.of(context).pop();
    ref.read(mainShellTabIndexProvider.notifier).state =
        MainShellScreen.moreTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(eventFormProvider(widget.eventId));
    final branding = ref.watch(appBrandingProvider);

    final palette = context.udaan;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandTokens.screenPadding,
              ),
              child: UdaanAuthTopBar(
                copy: _copy,
                title: branding.appName,
                onBack: () => Navigator.of(context).pop(),
                trailing: Semantics(
                  button: true,
                  label: _copy.profile,
                  child: IconButton(
                    onPressed: _openProfileTab,
                    icon: Icon(
                      Icons.person_outline,
                      color: palette.onBackground,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: formAsync.when(
                data: (schema) {
                  if (!_draftLoaded) {
                    return Center(
                      child: Semantics(
                        label: _copy.eventRegistrationLoadingForm,
                        liveRegion: true,
                        child: CircularProgressIndicator(
                          color: palette.primary,
                        ),
                      ),
                    );
                  }
                  return _buildForm(context, schema);
                },
                loading: () => Center(
                  child: Semantics(
                    label: _copy.eventRegistrationLoadingForm,
                    liveRegion: true,
                    child: CircularProgressIndicator(
                      color: palette.primary,
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(BrandTokens.screenPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: parseApiError(e).message,
                          liveRegion: true,
                          child: Text(
                            parseApiError(e).message,
                            textAlign: TextAlign.center,
                            style: udaanTextStyle(
                              context,
                              fontSize: 18,
                              color: palette.onBackground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          button: true,
                          label: _copy.eventRegistrationRetryLoad,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.primary,
                              foregroundColor: palette.onPrimary,
                              minimumSize: const Size(
                                BrandTokens.minTapTarget,
                                BrandTokens.minTapTarget,
                              ),
                            ),
                            onPressed: () => ref.invalidate(
                              eventFormProvider(widget.eventId),
                            ),
                            child: Text(_copy.retry),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, FormSchema schema) {
    if (!_accountDefaultsApplied) {
      _accountDefaultsApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyAccountDefaults(schema);
      });
    }

    final palette = context.udaan;
    final bySection = <String, List<FormFieldSchema>>{};
    for (final f in schema.fields) {
      bySection.putIfAbsent(f.sectionId, () => []).add(f);
    }
    final eventTitle = schema.event.title.isNotEmpty
        ? schema.event.title
        : widget.title;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        BrandTokens.screenPadding,
        8,
        BrandTokens.screenPadding,
        24,
      ),
      children: [
        Semantics(
          header: true,
          label: _copy.eventRegistrationTitle,
          child: Text(
            _copy.eventRegistrationTitle,
            style: udaanTextStyle(
              context,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: palette.onBackground,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: eventTitle,
          child: Text(
            eventTitle,
            style: udaanTextStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: palette.primaryGlow,
              height: 1.35,
            ),
          ),
        ),
        if (schema.unsupportedFields.isNotEmpty) ...[
          Builder(
            builder: (context) {
              if (!_unsupportedAnnounced) {
                _unsupportedAnnounced = true;
                final fieldNames = schema.unsupportedFields
                    .map((f) => registrationFieldDisplayLabel(f.label))
                    .join(', ');
                final notice = _copy.registrationUnsupportedFieldsSemantics(
                  notice: _copy.unsupportedFieldsNotice,
                  fieldNames: fieldNames,
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _announce(notice);
                });
              }
              final fieldNames = schema.unsupportedFields
                  .map((f) => registrationFieldDisplayLabel(f.label))
                  .join(', ');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Semantics(
                    label: _copy.registrationUnsupportedFieldsSemantics(
                      notice: _copy.unsupportedFieldsNotice,
                      fieldNames: fieldNames,
                    ),
                    liveRegion: true,
                    child: Text(
                      _copy.unsupportedFieldsNotice,
                      style: udaanTextStyle(
                        context,
                        fontSize: 16,
                        color: palette.error,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        for (final section in schema.sections) ...[
          if (bySection[section.id]?.isNotEmpty == true) ...[
            if (section.title.trim().isNotEmpty &&
                section.title.toLowerCase() != 'default') ...[
              const SizedBox(height: 8),
              Semantics(
                header: true,
                label: section.title,
                child: Text(
                  section.title,
                  style: udaanTextStyle(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: palette.onBackground,
                  ),
                ),
              ),
            ],
            for (final field in bySection[section.id]!)
              _fieldWidget(context, field, schema),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Semantics(
            label: _error,
            liveRegion: true,
            child: Text(
              _error!,
              style: udaanTextStyle(
                context,
                fontSize: 16,
                color: palette.error,
                height: 1.35,
              ),
            ),
          ),
        ],
        if (_success != null) ...[
          const SizedBox(height: 16),
          Semantics(
            label: _success,
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: palette.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _success!,
                    style: udaanTextStyle(
                      context,
                      fontSize: 16,
                      color: palette.onBackground,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Semantics(
          button: true,
          label: _submitting
              ? _copy.submittingRegistrationPleaseWait
              : _copy.submitRegistration,
          enabled: !_submitting,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              disabledBackgroundColor:
                  palette.primary.withValues(alpha: 0.5),
              minimumSize: const Size(double.infinity, 56),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _submitting ? null : () => _submit(schema),
            child: _submitting
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _copy.submitRegistration,
                        style: udaanTextStyle(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward, size: 22),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Single-select options as tappable rows — wraps long labels (no dropdown overflow).
  Widget _singleChoiceField(BuildContext context, FormFieldSchema field) {
    final selected = _values[field.key] as String?;
    return _fieldShell(
      context,
      field,
      Semantics(
        label: _fieldSemanticsLabel(field),
        value: selected,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final opt in field.options)
              registrationChoiceTile(
                context: context,
                label: opt,
                selected: selected == opt,
                isRadio: true,
                groupLabel: _fieldSemanticsLabel(field),
                onTap: () => _setFieldValue(field.key, opt),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fieldWidget(
    BuildContext context,
    FormFieldSchema field,
    FormSchema schema,
  ) {
    final palette = context.udaan;

    switch (field.type) {
      case 'textarea':
        return _textField(context: context, field: field, maxLines: 4);
      case 'select':
      case 'radio':
        return _singleChoiceField(context, field);
      case 'checkbox':
        final current = _values[field.key];
        if (field.options.length > 1) {
          final selected = current is List
              ? List<String>.from(current.map((e) => e.toString()))
              : <String>[];
          return _fieldShell(
            context,
            field,
            Semantics(
              label: _fieldSemanticsLabel(field),
              value: _copy.registrationMultiSelectSemanticsValue(selected),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final opt in field.options)
                    registrationChoiceTile(
                      context: context,
                      label: opt,
                      selected: selected.contains(opt),
                      isRadio: false,
                      groupLabel: _fieldSemanticsLabel(field),
                      onTap: () {
                        final next = List<String>.from(selected);
                        if (next.contains(opt)) {
                          next.remove(opt);
                        } else {
                          next.add(opt);
                        }
                        _setFieldValue(field.key, next);
                      },
                    ),
                ],
              ),
            ),
          );
        }
        final checked = current == true || current == '1';
        final consentLabel = registrationFieldDisplayLabel(field.label);
        return _fieldShell(
          context,
          field,
          Semantics(
            checked: checked,
            label: field.required ? '$consentLabel, required' : consentLabel,
            onTap: () => _setFieldValue(field.key, !checked),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _setFieldValue(field.key, !checked),
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: BrandTokens.a11yMinTapTarget,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        checked
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: palette.primaryGlow,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Text(
                            registrationFieldLabelText(field),
                            style: registrationFieldLabelStyle(
                              context,
                              required: field.required,
                            ).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case 'upload':
        final uploadValue = _uploadLabels[field.key];
        final uploading = _uploadProgress.containsKey(field.key);
        final progress = _uploadProgress[field.key];
        final uploadError = _uploadErrors[field.key];
        final percent = ((progress ?? 0) * 100).round().clamp(0, 100);
        final uploadLabel = registrationFieldDisplayLabel(field.label);
        return _fieldShell(
          context,
          field,
          Semantics(
              label: _fieldSemanticsLabel(field),
              hint: field.required ? _copy.registrationFieldRequired : null,
              value: uploading
                  ? _copy.registrationUploadProgressLabel(
                      uploadLabel,
                      percent,
                    )
                  : (uploadValue ?? _copy.registrationNoFileSelected),
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    button: true,
                    label: uploading
                        ? _copy.registrationUploadProgressLabel(
                            uploadLabel,
                            percent,
                          )
                        : uploadValue != null
                            ? _copy.registrationChangeFileSemantics(
                                uploadLabel,
                                uploadValue,
                                required: field.required,
                              )
                            : _copy.registrationChooseFileSemantics(
                                uploadLabel,
                                required: field.required,
                              ),
                    value: uploadValue,
                    enabled: !uploading && !_submitting,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.surfaceContainerHigh,
                        foregroundColor: palette.onBackground,
                        minimumSize: const Size(
                          double.infinity,
                          BrandTokens.minTapTarget,
                        ),
                      ),
                      onPressed: uploading || _submitting
                          ? null
                          : () => _pickFile(field, schema),
                      child: Text(
                        _uploadLabels[field.key] ?? _copy.chooseFile,
                        style: udaanTextStyle(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (uploading) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      label: _copy.registrationUploadProgressLabel(
                        uploadLabel,
                        percent,
                      ),
                      value: '$percent%',
                      liveRegion: true,
                      child: LinearProgressIndicator(
                        value: progress != null && progress > 0
                            ? progress.clamp(0.0, 1.0)
                            : null,
                      ),
                    ),
                  ],
                  if (uploadError != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      label: uploadError,
                      liveRegion: true,
                      child: Text(
                        uploadError,
                        style: udaanTextStyle(
                          context,
                          fontSize: 14,
                          color: palette.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: _copy.registrationUploadRetryLabel(
                        field.label,
                      ),
                      enabled: !uploading && !_submitting,
                      child: TextButton(
                        onPressed: uploading || _submitting
                            ? null
                            : () => _retryUpload(field, schema),
                        child: Text(_copy.retry),
                      ),
                    ),
                  ],
                ],
              ),
          ),
        );
      case 'number':
        return _textField(
          context: context,
          field: field,
          keyboardType: TextInputType.number,
        );
      case 'email':
        return _textField(
          context: context,
          field: field,
          keyboardType: TextInputType.emailAddress,
        );
      case 'phone':
        return _textField(
          context: context,
          field: field,
          keyboardType: TextInputType.phone,
        );
      case 'date':
        return _pickerField(
          context: context,
          field: field,
          onPick: _pickDate,
          hint: _copy.registrationPickerDateHint,
          icon: Icons.calendar_today,
        );
      case 'time':
        return _pickerField(
          context: context,
          field: field,
          onPick: _pickTime,
          hint: _copy.registrationPickerTimeHint,
          icon: Icons.schedule,
        );
      case 'datetime':
        return _pickerField(
          context: context,
          field: field,
          onPick: _pickDateTime,
          hint: _copy.registrationPickerDateTimeHint,
          icon: Icons.event,
        );
      case 'address':
        return _textField(
          context: context,
          field: field,
          maxLines: 4,
          keyboardType: TextInputType.streetAddress,
          textCapitalization: TextCapitalization.sentences,
          hintOverride:
              field.placeholder ?? _copy.registrationAddressHint,
        );
      default:
        return _textField(context: context, field: field);
    }
  }
}
