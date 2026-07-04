import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/storage/registration_draft_storage.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/udaan_text_styles.dart';
import '../../core/utils/keyboard_dismiss.dart';
import '../../core/widgets/accessible_html_content.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import 'form_field_validator.dart';
import 'models/form_schema.dart';
import 'form_visibility.dart';
import 'registration_account_prefill.dart';
import 'widgets/event_context_banner.dart';
import 'widgets/registration_form_styles.dart';
import 'widgets/registration_outcome_widgets.dart';

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
  final _uploadLabels = <String, dynamic>{};
  final _uploadProgress = <String, double>{};
  final _uploadErrors = <String, String>{};
  final _pendingUploads = <String, ({String path, String name})>{};
  final _fieldKeys = <String, GlobalKey>{};
  final _textControllers = <String, TextEditingController>{};
  final _scrollController = ScrollController();
  String? _error;
  int? _successEntryId;
  String? _successEventTitle;
  String? _validationFieldKey;
  String? _validationMessage;
  bool _submitting = false;
  bool _draftLoaded = false;
  bool _accountDefaultsApplied = false;
  int _currentPageIndex = 0;
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

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
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
        uploadLabels: {
          for (final entry in _uploadLabels.entries)
            entry.key: entry.value is List
                ? (entry.value as List).join(', ')
                : entry.value.toString(),
        },
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
    announce(context, message);
  }

  void _announcePageChange(FormSchema schema) {
    if (schema.pages.isEmpty) return;
    final page = schema.pages[_currentPageIndex.clamp(0, schema.pages.length - 1)];
    if (page.title.isNotEmpty) return;
    final pageLabel = _copy.registrationPageLabel(
      _currentPageIndex + 1,
      schema.pages.length,
    );
    _announce(pageLabel);
  }

  bool _submitBlocked(FormSchema schema) =>
      !schema.appSubmittable || schema.hasBlockingUnsupported;

  String? _submitBlockedMessage(FormSchema schema) {
    if (!schema.appSubmittable && schema.formWarnings.isNotEmpty) {
      return schema.formWarnings.join(' ');
    }
    if (schema.hasBlockingUnsupported) {
      final names = schema.unsupportedFields
          .where((u) => u.blocksSubmit || u.required)
          .map((u) => registrationFieldDisplayLabel(u.label))
          .join(', ');
      return '${_copy.unsupportedFieldsNotice} Unsupported fields: $names';
    }
    if (!schema.appSubmittable) {
      return _copy.registrationIncomplete;
    }
    return null;
  }

  List<FormFieldSchema> _visibleFieldsForPage(FormSchema schema) {
    final visible = visibleFormFields(schema, _values);
    if (schema.pages.isEmpty) return visible;
    return visible.where((f) => f.pageIndex == _currentPageIndex).toList();
  }

  FormFieldSchema? _firstInvalidField(
    FormSchema schema, {
    int? pageIndex,
  }) {
    final visible = visibleFormFields(schema, _values);
    final fields = pageIndex != null && schema.pages.isNotEmpty
        ? visible.where((f) => f.pageIndex == pageIndex)
        : visible;

    for (final field in fields) {
      final error = validateField(field, _values[field.key]);
      if (error != null) return field;
    }
    return null;
  }

  String _validationMessageFor(FormFieldSchema field) {
    return validateField(field, _values[field.key]) ??
        '${registrationFieldDisplayLabel(field.label)}. '
            '${_copy.registrationFieldRequired}';
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
        // Clear validation on a field that just became hidden.
        final schema = ref.read(eventFormProvider(widget.eventId)).value;
        if (schema != null && _validationFieldKey != null) {
          final invalidKey = _validationFieldKey!;
          FormFieldSchema? invalidField;
          for (final f in schema.fields) {
            if (f.key == invalidKey) {
              invalidField = f;
              break;
            }
          }
          if (invalidField != null &&
              !isFormFieldVisible(invalidField, schema.fields, _values)) {
            _validationFieldKey = null;
            _validationMessage = null;
          }
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
            ExcludeSemantics(
              child: Text(
                labelText,
                style: registrationFieldLabelStyle(
                  context,
                  required: field.required,
                ),
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
                child: ExcludeSemantics(
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
        child: ExcludeSemantics(
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
            textInputAction:
                maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
            onEditingComplete: () => dismissKeyboard(context),
            onFieldSubmitted: (_) => dismissKeyboard(context),
            onChanged:
                isAccountLocked ? null : (v) => _onTextFieldChanged(field, v),
          ),
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
      UdaanAccessibleButton(
        label: [
          _fieldSemanticsLabel(field),
          if (display != null) display,
          if (display == null) hint,
        ].join(', '),
        onPressed: () => onPick(field),
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

  List<String> _uploadIds(FormFieldSchema field) {
    final raw = _values[field.key];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw == null || raw.toString().trim().isEmpty) return const [];
    return [raw.toString()];
  }

  List<String> _uploadNames(FormFieldSchema field) {
    final raw = _uploadLabels[field.key];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw == null || raw.toString().trim().isEmpty) return const [];
    return [raw.toString()];
  }

  void _setUploadValue(FormFieldSchema field, List<String> ids, List<String> names) {
    if (field.isMultiFileUpload) {
      _values[field.key] = ids;
      _uploadLabels[field.key] = names;
    } else {
      _values[field.key] = ids.isEmpty ? null : ids.first;
      _uploadLabels[field.key] = names.isEmpty ? null : names.first;
    }
  }

  bool _allowedUploadExtension(String fileName, FormFieldSchema field) {
    if (field.allowedExt.isEmpty) return true;
    final parts = fileName.split('.');
    if (parts.length < 2) return false;
    return field.allowedExt.contains(parts.last.toLowerCase());
  }

  int schemaMaxFileMb(FormFieldSchema field, FormSchema schema) =>
      field.maxSizeMb ?? schema.maxFileMb;

  String? _uploadSizeError(FormSchema schema, FormFieldSchema field, PlatformFile file) {
    final maxMb = schemaMaxFileMb(field, schema);
    final maxBytes = maxMb * 1024 * 1024;
    final size = file.size;
    if (size > maxBytes) {
      return 'File is too large. Maximum size is $maxMb MB.';
    }
    return null;
  }

  Future<void> _uploadPickedFile(
    FormSchema schema,
    FormFieldSchema field, {
    required String path,
    required String name,
  }) async {
    setState(() {
      _error = null;
      _uploadErrors.remove(field.key);
      _uploadProgress[field.key] = 0;
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
            },
          );
      if (!mounted) return;
      final ids = List<String>.from(_uploadIds(field));
      final names = List<String>.from(_uploadNames(field));
      if (field.isMultiFileUpload) {
        ids.add(uploaded.uploadId);
        names.add(uploaded.fileName);
      } else {
        ids
          ..clear()
          ..add(uploaded.uploadId);
        names
          ..clear()
          ..add(uploaded.fileName);
      }
      setState(() {
        _setUploadValue(field, ids, names);
        _uploadProgress.remove(field.key);
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
        _uploadErrors[field.key] = message;
      });
    }
  }

  Future<void> _pickFile(FormFieldSchema field, FormSchema schema) async {
    final existing = _uploadIds(field);
    if (field.isMultiFileUpload && existing.length >= field.maxFiles) {
      final message =
          'You can upload at most ${field.maxFiles} files for ${field.label}.';
      setState(() => _uploadErrors[field.key] = message);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      withData: false,
      allowMultiple: field.isMultiFileUpload,
    );
    if (result == null || result.files.isEmpty) return;

    final files = field.isMultiFileUpload
        ? result.files
        : [result.files.single];

    for (final file in files) {
      if (file.path == null) continue;

      if (!_allowedUploadExtension(file.name, field)) {
        final allowed = field.allowedExt.join(', ');
        final message = allowed.isEmpty
            ? 'This file type is not allowed.'
            : 'Allowed file types: $allowed.';
        setState(() => _uploadErrors[field.key] = message);
        return;
      }

      final sizeError = _uploadSizeError(schema, field, file);
      if (sizeError != null) {
        setState(() => _uploadErrors[field.key] = sizeError);
        return;
      }

      if (field.isMultiFileUpload &&
          existing.length + files.indexOf(file) + 1 > field.maxFiles) {
        break;
      }

      _pendingUploads[field.key] = (path: file.path!, name: file.name);
      await _uploadPickedFile(
        schema,
        field,
        path: file.path!,
        name: file.name,
      );
    }
  }

  Future<void> _retryUpload(FormFieldSchema field, FormSchema schema) async {
    final pending = _pendingUploads[field.key];
    if (pending == null) {
      await _pickFile(field, schema);
      return;
    }
    await _uploadPickedFile(
      schema,
      field,
      path: pending.path,
      name: pending.name,
    );
  }

  Future<void> _goToNextPage(FormSchema schema) async {
    final invalid = _firstInvalidField(schema, pageIndex: _currentPageIndex);
    if (invalid != null) {
      final message = _validationMessageFor(invalid);
      setState(() {
        _validationFieldKey = invalid.key;
        _validationMessage = message;
      });
      _scrollToField(invalid.key);
      return;
    }
    if (_currentPageIndex < schema.pages.length - 1) {
      setState(() {
        _currentPageIndex++;
        _validationFieldKey = null;
        _validationMessage = null;
      });
      _scrollToTop();
      _announcePageChange(schema);
    }
  }

  void _goToPreviousPage(FormSchema schema) {
    if (_currentPageIndex <= 0) return;
    setState(() {
      _currentPageIndex--;
      _validationFieldKey = null;
      _validationMessage = null;
    });
    _scrollToTop();
    _announcePageChange(schema);
  }

  Future<void> _submit(FormSchema schema) async {
    if (_submitBlocked(schema)) {
      final message = _submitBlockedMessage(schema) ?? _copy.registrationIncomplete;
      setState(() => _error = message);
      _scrollToTop();
      return;
    }

    final invalid = _firstInvalidField(schema);
    if (invalid != null) {
      final message = _validationMessageFor(invalid);
      setState(() {
        _error = null;
        _successEntryId = null;
        _successEventTitle = null;
        _validationFieldKey = invalid.key;
        _validationMessage = message;
      });
      if (schema.pages.isNotEmpty) {
        setState(() => _currentPageIndex = invalid.pageIndex);
      }
      _scrollToField(invalid.key);
      return;
    }

    setState(() {
      _error = null;
      _successEntryId = null;
      _successEventTitle = null;
      _validationFieldKey = null;
      _validationMessage = null;
      _submitting = true;
    });

    try {
      final result = await ref.read(radioudaanApiProvider).submitRegistration(
            eventId: widget.eventId,
            payload: visibleFormPayload(schema, _values),
          );
      await _clearDraft();
      final eventTitle = schema.event.title.trim().isNotEmpty
          ? schema.event.title.trim()
          : widget.title.trim();
      setState(() {
        _values.clear();
        _uploadLabels.clear();
        _pendingUploads.clear();
        _successEntryId = result.entryId;
        _successEventTitle = eventTitle;
        for (final controller in _textControllers.values) {
          controller.clear();
        }
      });
    } catch (e) {
      final message = parseApiError(e).message;
      setState(() => _error = message);
      _scrollToTop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(eventFormProvider(widget.eventId));

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
                title: widget.title,
                onBack: () => Navigator.of(context).pop(),
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
                  if (_successEntryId != null) {
                    return RegistrationSuccessView(
                      copy: _copy,
                      eventTitle: _successEventTitle ?? widget.title,
                      entryId: _successEntryId!,
                      onBack: () => Navigator.of(context).pop(),
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
                          child: ExcludeSemantics(
                            child: Text(                            parseApiError(e).message,
                            textAlign: TextAlign.center,
                            style: udaanTextStyle(
                              context,
                              fontSize: 18,
                              color: palette.onBackground,
                            ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          button: true,
                          label: _copy.eventRegistrationRetryLoad,
                          child: ExcludeSemantics(
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
    final pageFields = _visibleFieldsForPage(schema);
    final bySection = <String, List<FormFieldSchema>>{};
    for (final f in pageFields) {
      bySection.putIfAbsent(f.sectionId, () => []).add(f);
    }
    final submitBlocked = _submitBlocked(schema);
    final onLastPage = schema.pages.isEmpty ||
        _currentPageIndex >= schema.pages.length - 1;

    return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
        BrandTokens.screenPadding,
        8,
        BrandTokens.screenPadding,
        24,
      ),
      children: [
        if (_error != null) ...[
          RegistrationErrorBanner(copy: _copy, message: _error!),
          const SizedBox(height: 16),
        ],
        if (schema.formWarnings.isNotEmpty) ...[
          Semantics(
            liveRegion: true,
            label: schema.formWarnings.join('. '),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.error),
              ),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final warning in schema.formWarnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          warning,
                          style: udaanTextStyle(
                            context,
                            fontSize: 16,
                            color: palette.error,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (submitBlocked) ...[
          Semantics(
            liveRegion: true,
            label: _submitBlockedMessage(schema) ?? _copy.registrationIncomplete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.error),
              ),
              child: ExcludeSemantics(
                child: Text(
                  _submitBlockedMessage(schema) ?? _copy.registrationIncomplete,
                  style: udaanTextStyle(
                    context,
                    fontSize: 16,
                    color: palette.error,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        EventContextBanner(copy: _copy, event: schema.event),
        UdaanScreenHeader(
          title: _copy.eventRegistrationTitle,
          style: udaanTextStyle(
            context,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: palette.onBackground,
            height: 1.15,
          ),
        ),
        if (schema.pages.isNotEmpty) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final page = schema
                  .pages[_currentPageIndex.clamp(0, schema.pages.length - 1)];
              final pageLabel = _copy.registrationPageLabel(
                _currentPageIndex + 1,
                schema.pages.length,
              );
              final semanticsLabel = page.title.isNotEmpty
                  ? '$pageLabel. ${page.title}'
                  : pageLabel;
              final displayText =
                  page.title.isNotEmpty ? page.title : pageLabel;
              return Semantics(
                label: semanticsLabel,
                child: ExcludeSemantics(
                  child: Text(
                    displayText,
                    style: udaanTextStyle(
                      context,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.onBackground,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        if (schema.unsupportedFields.isNotEmpty) ...[
          Builder(
            builder: (context) {
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
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _copy.unsupportedFieldsNotice,
                            style: udaanTextStyle(
                              context,
                              fontSize: 16,
                              color: palette.error,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fieldNames,
                            style: udaanTextStyle(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: palette.onBackground,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        Semantics(
          explicitChildNodes: true,
          child: FocusTraversalGroup(
            child: Column(
              children: [
                for (final section in schema.sections) ...[
                  if (bySection[section.id]?.isNotEmpty == true) ...[
                    if (section.title.trim().isNotEmpty &&
                        section.title.toLowerCase() != 'default') ...[
                      const SizedBox(height: 8),
                      Semantics(
                        header: true,
                        label: section.title,
                        child: ExcludeSemantics(
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
                      ),
                    ],
                    for (final field in bySection[section.id]!)
                      _fieldWidget(context, field, schema),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (schema.pages.isNotEmpty && _currentPageIndex > 0) ...[
          UdaanAccessibleButton(
            label: '${_copy.registrationPreviousPage} page',
            onPressed: () => _goToPreviousPage(schema),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: palette.primaryGlow),
              ),
              onPressed: () => _goToPreviousPage(schema),
              child: Text(
                _copy.registrationPreviousPage,
                style: udaanTextStyle(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (schema.pages.isNotEmpty && !onLastPage) ...[
          UdaanAccessibleButton(
            label: '${_copy.registrationNextPage} page',
            onPressed: () => _goToNextPage(schema),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: () => _goToNextPage(schema),
              child: Text(
                _copy.registrationNextPage,
                style: udaanTextStyle(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ] else ...[
          UdaanAccessibleButton(
            label: _submitting
                ? _copy.submittingRegistrationPleaseWait
                : _copy.submitRegistration,
            enabled: !_submitting && !submitBlocked,
            onPressed: _submitting || submitBlocked ? null : () => _submit(schema),
            child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  disabledBackgroundColor:
                      palette.primary.withValues(alpha: 0.5),
                  minimumSize: const Size(double.infinity, 56),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitting || submitBlocked
                    ? null
                    : () => _submit(schema),
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
                          Icon(Icons.arrow_forward, size: 22),
                        ],
                      ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sliderField(BuildContext context, FormFieldSchema field) {
    final palette = context.udaan;
    final min = field.min ?? 0;
    final max = field.max ?? 100;
    final step = field.step ?? 1;
    final raw = _values[field.key];
    var current = double.tryParse(raw?.toString() ?? '') ?? min;
    current = current.clamp(min, max);
    final display = current == current.roundToDouble()
        ? current.round().toString()
        : current.toStringAsFixed(1);

    return _fieldShell(
      context,
      field,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              display,
              style: udaanTextStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.primaryGlow,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: current,
            min: min,
            max: max,
            divisions:
                step > 0 ? ((max - min) / step).round().clamp(1, 200) : null,
            label: '${_fieldSemanticsLabel(field)}, $display',
            onChanged: _submitting
                ? null
                : (value) => _setFieldValue(
                      field.key,
                      value == value.roundToDouble()
                          ? value.round().toString()
                          : value.toStringAsFixed(1),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _singleChoiceField(BuildContext context, FormFieldSchema field) {
    final selected = _values[field.key] as String?;
    final options = field.effectiveChoiceOptions;
    return _fieldShell(
      context,
      field,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final opt in options)
            registrationChoiceTile(
              context: context,
              label: opt.label,
              selected: selected == opt.value || selected == opt.label,
              isRadio: true,
              groupLabel: _fieldSemanticsLabel(field),
              onTap: () => _setFieldValue(field.key, opt.value),
            ),
        ],
      ),
    );
  }

  void _setSubfieldValue(
    FormFieldSchema field,
    FormSubfield sub,
    String value,
  ) {
    final current = _values[field.key];
    final map = current is Map
        ? Map<String, dynamic>.from(current)
        : <String, dynamic>{};
    map[sub.key] = value;
    _setFieldValue(field.key, map);
  }

  Widget _subfieldsField(BuildContext context, FormFieldSchema field) {
    final current = _values[field.key];
    final map = current is Map ? Map<String, dynamic>.from(current) : {};

    return _fieldShell(
      context,
      field,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final sub in field.subfields) ...[
            ExcludeSemantics(
              child: Text(
                sub.required ? '${sub.label} *' : sub.label,
                style: registrationFieldLabelStyle(
                  context,
                  required: sub.required,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: sub.required ? '${sub.label}, required' : sub.label,
              textField: true,
              child: ExcludeSemantics(
                child: TextFormField(
                  initialValue: map[sub.key]?.toString() ?? '',
                  style: registrationFieldInputStyle(context),
                  decoration: registrationFieldDecoration(
                    context,
                    hint: sub.label,
                    errorText: _validationFieldKey == field.key
                        ? _validationMessage
                        : null,
                  ),
                  keyboardType: field.type == 'address'
                      ? TextInputType.streetAddress
                      : TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () => dismissKeyboard(context),
                  onFieldSubmitted: (_) => dismissKeyboard(context),
                  onChanged: (v) => _setSubfieldValue(field, sub, v),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _consentField(BuildContext context, FormFieldSchema field) {
    final checked = _values[field.key] == true || _values[field.key] == '1';
    final consentLabel = registrationFieldDisplayLabel(field.label);
    final palette = context.udaan;

    return _fieldShell(
      context,
      field,
      Semantics(
        checked: checked,
        label: field.required ? '$consentLabel, required' : consentLabel,
        onTap: () => _setFieldValue(field.key, !checked),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
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
                      ],
                    ),
                  ),
                ),
              ),
              if (field.consentHtml != null &&
                  field.consentHtml!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                AccessibleHtmlContent(
                  html: field.consentHtml!,
                  textStyle: udaanTextStyle(
                    context,
                    fontSize: 16,
                    color: palette.onBackground.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
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

    if (field.hasSubfields &&
        (field.type == 'address' || field.type == 'name' || field.type == 'text')) {
      return _subfieldsField(context, field);
    }

    switch (field.type) {
      case 'info':
        final html = field.infoHtml?.trim() ?? '';
        if (html.isEmpty) return const SizedBox.shrink();
        final infoLabel = registrationFieldDisplayLabel(field.label);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (infoLabel.isNotEmpty) ...[
                Semantics(
                  header: true,
                  label: infoLabel,
                  child: ExcludeSemantics(
                    child: Text(
                      infoLabel,
                      style: registrationFieldLabelStyle(context),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ExcludeSemantics(
                child: AccessibleHtmlContent(html: html),
              ),
            ],
          ),
        );
      case 'textarea':
        return _textField(context: context, field: field, maxLines: 4);
      case 'select':
      case 'radio':
      case 'rating':
        return _singleChoiceField(context, field);
      case 'checkbox':
        final current = _values[field.key];
        final multiOptions = field.effectiveChoiceOptions;
        if (multiOptions.length > 1) {
          final selected = current is List
              ? List<String>.from(current.map((e) => e.toString()))
              : <String>[];
          return _fieldShell(
            context,
            field,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final opt in multiOptions)
                  registrationChoiceTile(
                    context: context,
                    label: opt.label,
                    selected: selected.contains(opt.value) ||
                        selected.contains(opt.label),
                    isRadio: false,
                    groupLabel: _fieldSemanticsLabel(field),
                    onTap: () {
                      final next = List<String>.from(selected);
                      if (next.contains(opt.value)) {
                        next.remove(opt.value);
                      } else if (next.contains(opt.label)) {
                        next.remove(opt.label);
                      } else {
                        next.add(opt.value);
                      }
                      _setFieldValue(field.key, next);
                    },
                  ),
              ],
            ),
          );
        }
        return _consentField(context, field);
      case 'upload':
        final uploadNames = _uploadNames(field);
        final uploadValue = uploadNames.isEmpty ? null : uploadNames.join(', ');
        final uploading = _uploadProgress.containsKey(field.key);
        final progress = _uploadProgress[field.key];
        final uploadError = _uploadErrors[field.key];
        final percent = ((progress ?? 0) * 100).round().clamp(0, 100);
        final uploadLabel = registrationFieldDisplayLabel(field.label);
        final atMax = field.isMultiFileUpload &&
            _uploadIds(field).length >= field.maxFiles;
        final pickEnabled = !uploading && !_submitting && !atMax;
        final uploadSemanticsLabel = uploading
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
                  );
        return _fieldShell(
          context,
          field,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  if (uploadNames.isNotEmpty) ...[
                    for (final name in uploadNames)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ExcludeSemantics(
                          child: Text(
                            name,
                            style: udaanTextStyle(
                              context,
                              fontSize: 16,
                              color: palette.onBackground,
                            ),
                          ),
                        ),
                      ),
                  ],
                  UdaanAccessibleButton(
                    label: uploadSemanticsLabel,
                    enabled: pickEnabled,
                    onPressed:
                        pickEnabled ? () => _pickFile(field, schema) : null,
                    child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.surfaceContainerHigh,
                          foregroundColor: palette.onBackground,
                          minimumSize: const Size(
                            double.infinity,
                            BrandTokens.minTapTarget,
                          ),
                        ),
                        onPressed: pickEnabled
                            ? () => _pickFile(field, schema)
                            : null,
                        child: Text(
                          atMax
                              ? 'Maximum ${field.maxFiles} files selected'
                              : (field.isMultiFileUpload
                                  ? _copy.chooseFile
                                  : (_uploadNames(field).isEmpty
                                      ? _copy.chooseFile
                                      : _uploadNames(field).first)),
                          style: udaanTextStyle(
                            context,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ),
                  if (field.isMultiFileUpload && field.maxFiles > 1) ...[
                    const SizedBox(height: 6),
                    ExcludeSemantics(
                      child: Text(
                        '${_uploadIds(field).length} of ${field.maxFiles} files',
                        style: udaanTextStyle(
                          context,
                          fontSize: 14,
                          color: palette.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  if (uploading) ...[
                    const SizedBox(height: 8),
                    ExcludeSemantics(
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
                      child: ExcludeSemantics(
                        child: Text(
                          uploadError,
                          style: udaanTextStyle(
                            context,
                            fontSize: 14,
                            color: palette.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    UdaanAccessibleButton(
                      label: _copy.registrationUploadRetryLabel(
                        field.label,
                      ),
                      enabled: !uploading && !_submitting,
                      onPressed: uploading || _submitting
                          ? null
                          : () => _retryUpload(field, schema),
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
        );
      case 'number':
        return _textField(
          context: context,
          field: field,
          keyboardType: TextInputType.number,
        );
      case 'slider':
        return _sliderField(context, field);
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
      case 'url':
        return _textField(
          context: context,
          field: field,
          keyboardType: TextInputType.url,
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
