import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_to_words.dart';
import '../../data/models/invoice_model.dart';
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

class ItemControllers {
  final description = TextEditingController();
  final quantity = TextEditingController();
  final length = TextEditingController();
  final breadth = TextEditingController();
  final rate = TextEditingController();

  double area = 0.0;
  double price = 0.0;

  void dispose() {
    description.dispose();
    quantity.dispose();
    length.dispose();
    breadth.dispose();
    rate.dispose();
  }
}

class _FormPageState extends State<FormPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _submitted = false;

  // Invoice Identifiers
  final _billNoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  static const String _billCounterKey = 'bill_counter';

  // Customer Information Controllers
  final _clientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Items List
  final List<ItemControllers> _itemControllers = [];

  // Toggle & Extra Charges
  bool _locationOutsideParrys = false;
  final _extraChargesController = TextEditingController(text: '500.00');

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

    // Load and set the next unique bill number from local storage
    _loadNextBillNumber();

    // Real-time listener: update totals when extra charges amount changes
    _extraChargesController.addListener(() => setState(() {}));

    // Initialize with one empty item as shown in the mockup Screen 1
    _addNewItem();
  }

  /// Loads the last used bill counter from SharedPreferences and sets the next number
  Future<void> _loadNextBillNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCounter = prefs.getInt(_billCounterKey) ?? 0;
    final nextCounter = lastCounter + 1;
    if (mounted) {
      setState(() {
        _billNoController.text = 'INV-${nextCounter.toString().padLeft(3, '0')}';
      });
    }
  }

  /// Persists the current bill counter so the next bill gets a higher number
  Future<void> _saveBillCounter() async {
    final prefs = await SharedPreferences.getInstance();
    // Parse the numeric part from the current bill number (e.g. INV-007 -> 7)
    final text = _billNoController.text.trim();
    final match = RegExp(r'(\d+)$').firstMatch(text);
    if (match != null) {
      final counter = int.tryParse(match.group(1)!) ?? 0;
      await prefs.setInt(_billCounterKey, counter);
    }
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _clientNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _extraChargesController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    _successController.dispose();
    super.dispose();
  }

  /// Adds a new empty item or an item pre-filled with data
  void _addNewItem({
    String desc = '',
    String qty = '',
    String len = '',
    String brd = '',
    String rt = '',
  }) {
    final controllers = ItemControllers();
    controllers.description.text = desc;
    controllers.quantity.text = qty;
    controllers.length.text = len;
    controllers.breadth.text = brd;
    controllers.rate.text = rt;

    _calculateItemValues(controllers);

    // Attach real-time listeners for instant auto-calculations
    controllers.quantity.addListener(() => _calculateItemValues(controllers));
    controllers.length.addListener(() => _calculateItemValues(controllers));
    controllers.breadth.addListener(() => _calculateItemValues(controllers));
    controllers.rate.addListener(() => _calculateItemValues(controllers));

    setState(() {
      _itemControllers.add(controllers);
    });
  }

  /// Recalculates the Area and Price of a single item
  void _calculateItemValues(ItemControllers controllers) {
    final qty = int.tryParse(controllers.quantity.text) ?? 0;
    final len = double.tryParse(controllers.length.text) ?? 0.0;
    final brd = double.tryParse(controllers.breadth.text) ?? 0.0;
    final rt = double.tryParse(controllers.rate.text) ?? 0.0;

    setState(() {
      controllers.area = len * brd;
      controllers.price = qty * controllers.area * rt;
    });
  }

  /// Deletes an item from the list
  void _removeItem(int index) {
    if (_itemControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one item is required in the invoice.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      final removed = _itemControllers.removeAt(index);
      removed.dispose();
    });
  }

  /// Populates the exact values from Screen 2 of the mockup
  void _loadMockData() {
    setState(() {
      // Clear current items
      for (var c in _itemControllers) {
        c.dispose();
      }
      _itemControllers.clear();

      // Customer Info
      _clientNameController.text = 'Prabu G';
      _phoneController.text = '9876543210';
      _addressController.text = 'No. 12, Main Street, Chennai';

      // Item 1
      _addNewItem(
        desc: 'Flex Banner 8x4 ft',
        qty: '2',
        len: '3',
        brd: '6',
        rt: '120',
      );

      // Item 2
      _addNewItem(
        desc: 'Vinyl Printing',
        qty: '1',
        len: '2',
        brd: '10',
        rt: '150',
      );

      // Toggle & Extra Charges
      _locationOutsideParrys = true;
      _extraChargesController.text = '500.00';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mockup invoice details populated successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// Calculates the Sub Total of the invoice
  double get _subTotal {
    return _itemControllers.fold(0.0, (sum, item) => sum + item.price);
  }

  /// Calculates the Extra Charges if toggled on
  double get _extraCharges {
    if (!_locationOutsideParrys) return 0.0;
    return double.tryParse(_extraChargesController.text) ?? 0.0;
  }

  /// Calculates the Grand Total of the invoice
  double get _grandTotal {
    return _subTotal + _extraCharges;
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

  /// Packages form data into our standard InvoiceData model
  InvoiceData _packageInvoiceData() {
    final itemsList = _itemControllers.map((c) {
      return InvoiceItem(
        description: c.description.text.trim(),
        quantity: int.tryParse(c.quantity.text) ?? 0,
        length: double.tryParse(c.length.text) ?? 0.0,
        breadth: double.tryParse(c.breadth.text) ?? 0.0,
        rate: double.tryParse(c.rate.text) ?? 0.0,
      );
    }).toList();

    return InvoiceData(
      billNo: _billNoController.text.trim(),
      date: _selectedDate,
      clientName: _clientNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      items: itemsList,
      locationOutsideParrys: _locationOutsideParrys,
      extraCharges: double.tryParse(_extraChargesController.text) ?? 0.0,
      submittedAt: DateTime.now(),
    );
  }

  /// Triggers PDF Generation and shows native layout dialog
  Future<void> _handleGeneratePdf() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct errors in the form before generating.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final invoiceData = _packageInvoiceData();
    final pdfBytes = await PdfService.generateInvoicePdf(invoiceData);

    if (!mounted) return;

    // Persist the current bill number counter before showing success
    await _saveBillCounter();

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
    unawaited(_successController.forward());

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Invoice_${invoiceData.billNo}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  /// Triggers Saving Draft logic
  void _handleSaveDraft() {
    if (_clientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client Name is required to save a draft.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft invoice ${_billNoController.text} saved successfully!'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _clientNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    for (var c in _itemControllers) {
      c.dispose();
    }
    _itemControllers.clear();
    _locationOutsideParrys = false;
    _extraChargesController.text = '500.00';
    _successController.reset();

    setState(() {
      _submitted = false;
      _selectedDate = DateTime.now();
    });

    // Load the next unique bill number for the fresh form
    _loadNextBillNumber();
    _addNewItem();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Back button pressed')),
            );
          },
        ),
        title: Text(
          'Create Invoice',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E1B4B),
          ),
        ),
        actions: [
          // Developers load mockup values helper
          TextButton.icon(
            onPressed: _loadMockData,
            icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
            label: const Text(
              'Mock',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: widget.onToggleTheme,
          ),
          TextButton.icon(
            onPressed: _handleSaveDraft,
            icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 18),
            label: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spaceS),
        ],
      ),
      body: Stack(
        children: [
          // Premium glowing background orbs (subtle)
          if (!isDark) ...[
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.03),
                ),
              ),
            ),
          ],

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppConstants.spaceS),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: AppConstants.durationNormalMs),
                        child: _submitted
                            ? _buildSuccessCard(theme, isDark)
                            : _buildInvoiceForm(theme, isDark),
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

  Widget _buildInvoiceForm(ThemeData theme, bool isDark) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── BILL DETAILS CARD ───────────────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceM),
              child: Row(
                children: [
                  // Bill No input
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bill No.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _billNoController,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  // Date Picker
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd-MMM-yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spaceL),

          // ─── CUSTOMER INFORMATION ────────────────────────────────────────────
          _buildSectionHeader(theme, 'Customer Information'),
          const SizedBox(height: AppConstants.spaceM),

          _buildField(
            controller: _clientNameController,
            label: 'Client Name',
            hint: 'Enter client name',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Client Name is required' : null,
          ),
          const SizedBox(height: AppConstants.spaceM),

          _buildField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone number is required';
              if (v.trim().length < 10) return 'Enter a valid phone number';
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spaceM),

          _buildField(
            controller: _addressController,
            label: 'Address',
            hint: 'Enter address',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            isDark: isDark,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
          ),
          const SizedBox(height: AppConstants.spaceXL),

          // ─── ITEM DETAILS ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(theme, 'Item Details${_itemControllers.length > 1 ? " (${_itemControllers.length})" : ""}'),
              TextButton.icon(
                onPressed: () => _addNewItem(),
                icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text(
                  'Add Item',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceM),

          // Render list of item cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemControllers.length,
            itemBuilder: (context, index) {
              final controllers = _itemControllers[index];
              return _buildItemCard(theme, controllers, index, isDark);
            },
          ),

          const SizedBox(height: AppConstants.spaceM),

          // Add Another Item Button (mockup style)
          InkWell(
            onTap: () => _addNewItem(),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark.withOpacity(0.4) : const Color(0xFFF3E8FF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Another Item',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),

          // ─── LOCATION TOGGLE SECTION ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Location Outside Parrys?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Location Info'),
                                content: const Text('Charges apply if delivery location is outside the local Parrys area.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  )
                                ],
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _locationOutsideParrys,
                      onChanged: (val) {
                        setState(() {
                          _locationOutsideParrys = val;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                if (_locationOutsideParrys) ...[
                  const SizedBox(height: AppConstants.spaceM),
                  _buildField(
                    controller: _extraChargesController,
                    label: 'Extra Charges (₹)',
                    hint: '500.00',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Charges are required';
                      if (double.tryParse(v) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),

          // ─── INVOICE SUMMARY CARD ────────────────────────────────────────────
          _buildSectionHeader(theme, 'Invoice Summary'),
          const SizedBox(height: AppConstants.spaceM),

          Card(
            margin: EdgeInsets.zero,
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceL),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sub Total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(_subTotal),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extra Charges',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(_extraCharges),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(_grandTotal),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spaceL),

                  // Amount in Words Tinted Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1F35) : const Color(0xFFF3E8FF).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount in Words',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                NumberToWords.convert(_grandTotal),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF4A148C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),

          // ─── ACTION BUTTONS ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleSaveDraft,
                  icon: const Icon(Icons.file_download_outlined, size: 20),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleGeneratePdf,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: Text(_isSubmitting ? 'Generating...' : 'Generate PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ThemeData theme, ItemControllers controllers, int index, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceM),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge circle index
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Trash can delete button
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Description
            _buildField(
              controller: controllers.description,
              label: 'Description',
              hint: 'Enter description',
              icon: Icons.edit_note_rounded,
              isDark: isDark,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Quantity
            _buildField(
              controller: controllers.quantity,
              label: 'Quantity',
              hint: 'Enter quantity',
              icon: Icons.tag_rounded,
              keyboardType: TextInputType.number,
              isDark: isDark,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Quantity is required';
                if (int.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Dimensions Row (Length and Breadth separated by "x")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dimensions (ft)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E1B4B),
                      ),
                    ),
                    const Text(' *', style: TextStyle(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDimensionField(
                        controller: controllers.length,
                        label: 'Length',
                        hint: 'Enter length',
                        isDark: isDark,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      child: Text(
                        '×',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildDimensionField(
                        controller: controllers.breadth,
                        label: 'Breadth',
                        hint: 'Enter breadth',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Calculated Area & Entered Rate
            Row(
              children: [
                Expanded(
                  child: _buildCalculatedField(
                    label: 'Area (Sq.Ft)',
                    value: controllers.area.toStringAsFixed(2),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceM),
                Expanded(
                  child: _buildField(
                    controller: controllers.rate,
                    label: 'Rate (₹ / Sq.Ft)',
                    hint: 'Enter rate',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Rate is required';
                      if (double.tryParse(v) == null) return 'Enter a valid rate';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Calculated Total Price
            _buildCalculatedField(
              label: 'Price (₹)',
              value: NumberFormat.currency(locale: 'en_IN', symbol: '₹ ').format(controllers.price),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String label) {
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
            fontWeight: FontWeight.w800,
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
    final fillColor = isDark ? AppColors.cardDark.withOpacity(0.5) : const Color(0xFFF9F9FA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E1B4B),
              ),
            ),
            const Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: fillColor,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
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
        ),
      ],
    );
  }

  Widget _buildDimensionField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final fillColor = isDark ? AppColors.cardDark.withOpacity(0.5) : const Color(0xFFF9F9FA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '$label is required';
            if (double.tryParse(v) == null) return 'Invalid';
            return null;
          },
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: fillColor,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatedField({
    required String label,
    required String value,
    required bool isDark,
  }) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final fillColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Auto calculated)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessCard(ThemeData theme, bool isDark) {
    return Card(
      key: const ValueKey('success'),
      margin: EdgeInsets.zero,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXL),
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
              'Invoice Created!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: AppConstants.spaceS),
            Text(
              'Your invoice PDF has been successfully generated and opened for printing or saving.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppConstants.spaceXL),
            OutlinedButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Create Another Invoice'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceL,
                  vertical: AppConstants.spaceM,
                ),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
