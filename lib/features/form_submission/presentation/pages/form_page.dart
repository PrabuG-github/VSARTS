import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../services/pdf_service.dart';

class FormPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const FormPage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _submitted = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: widget.isDarkMode ? AppColors.cardDark : AppColors.cardLight,
              onSurface: widget.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await Future<void>.delayed(const Duration(milliseconds: 800));

    final formData = FormData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      date: _selectedDate,
      submittedAt: DateTime.now(),
    );

    final pdfBytes = await PdfService.generateFormPdf(formData);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
    unawaited(_successController.forward());

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'VSARTS_Submission_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _subjectController.clear();
    _messageController.clear();
    _successController.reset();
    setState(() {
      _submitted = false;
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          // Background orb decorations
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.07),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // AppBar
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spaceS),
                      Text(
                        'VSARTS Studio',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: widget.onToggleTheme,
                    ),
                    const SizedBox(width: AppConstants.spaceS),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppConstants.spaceM),

                      // Header
                      Text(
                        'Submit a\nRequest Form',
                        style: theme.textTheme.displayLarge?.copyWith(height: 1.15),
                      ),
                      const SizedBox(height: AppConstants.spaceS),
                      Text(
                        'Fill in the details below. On submission, a PDF will be generated and opened for you to save or share.',
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: AppConstants.spaceXL),

                      // Form Card
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: AppConstants.durationNormalMs),
                        child: _submitted
                            ? _buildSuccessCard(theme, isDark)
                            : _buildFormCard(theme, isDark),
                      ),

                      const SizedBox(height: AppConstants.spaceXXL),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme, bool isDark) {
    return Container(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(AppConstants.spaceL),
      decoration: _cardDecoration(isDark),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'Personal Information'),
            const SizedBox(height: AppConstants.spaceM),

            // Full Name
            _buildField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'e.g. Jane Doe',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Email
            _buildField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'jane@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailReg.hasMatch(v.trim())) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Phone
            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+1 234 567 8900',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
            ),

            const SizedBox(height: AppConstants.spaceXL),
            _sectionLabel(theme, 'Request Details'),
            const SizedBox(height: AppConstants.spaceM),

            // Subject
            _buildField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'e.g. Project Inquiry',
              icon: Icons.topic_outlined,
              isDark: isDark,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: _buildField(
                  controller: TextEditingController(
                    text: DateFormat('dd MMM yyyy').format(_selectedDate),
                  ),
                  label: 'Preferred Date',
                  hint: 'Select a date',
                  icon: Icons.calendar_today_outlined,
                  isDark: isDark,
                  validator: (_) => null,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Message
            _buildField(
              controller: _messageController,
              label: 'Message',
              hint: 'Write your message here...',
              icon: Icons.message_outlined,
              maxLines: 5,
              isDark: isDark,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
            ),

            const SizedBox(height: AppConstants.spaceXL),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: AppConstants.durationNormalMs),
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Generating PDF...' : 'Submit & Generate PDF',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
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

  Widget _buildSuccessCard(ThemeData theme, bool isDark) {
    return Container(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(AppConstants.spaceXL),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.success, Color(0xFF34D399)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: AppConstants.spaceL),
          Text(
            'PDF Generated!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppConstants.spaceS),
          Text(
            'Your form has been submitted and a PDF has been opened for you to preview, save, or share.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.spaceXL),
          OutlinedButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Submit Another Form'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceL,
                vertical: AppConstants.spaceM,
              ),
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppConstants.spaceS),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final fillColor = isDark
        ? AppColors.cardDark.withValues(alpha: 0.6)
        : AppColors.bgLight;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: fillColor,
        labelStyle: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
              .withValues(alpha: 0.6),
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM,
          vertical: maxLines > 1 ? AppConstants.spaceM : AppConstants.spaceS + 4,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
