import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StopEditorResult {
  const StopEditorResult({
    required this.location,
    required this.quantity,
    required this.contact,
  });
  final String location, contact;
  final double quantity;
}

class StopEditorSheet extends StatefulWidget {
  const StopEditorSheet({
    required this.isPickup,
    this.initial,
    this.focusContact = false,
    this.contacts = const [],
    super.key,
  });
  final bool isPickup, focusContact;
  final StopEditorResult? initial;
  final List<String> contacts;
  @override
  State<StopEditorSheet> createState() => _StopEditorSheetState();
}

class _StopEditorSheetState extends State<StopEditorSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _location, _quantity;
  String? _selectedContact;
  late final List<String> _contacts;
  @override
  void initState() {
    super.initState();
    _location = TextEditingController(text: widget.initial?.location ?? '');
    final q = widget.initial?.quantity;
    _quantity = TextEditingController(
      text: q == null
          ? ''
          : q == q.roundToDouble()
          ? q.toInt().toString()
          : q.toString(),
    );
    final existingContact = widget.initial?.contact.trim() ?? '';
    _selectedContact = existingContact.isEmpty ? null : existingContact;
    _contacts = [...widget.contacts];
    if (_selectedContact != null && !_contacts.contains(_selectedContact)) {
      _contacts.add(_selectedContact!);
    }
  }

  @override
  void dispose() {
    _location.dispose();
    _quantity.dispose();
    super.dispose();
  }

  InputDecoration _input(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xff8790a4),
      fontSize: AppTextStyles.bodySize,
    ),
    prefixIcon: Icon(icon, color: const Color(0xff596681), size: 20),
    filled: true,
    fillColor: const Color(0xfff8f9fd),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffdbe1ed)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffdbe1ed)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.orange),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final title = widget.initial == null
        ? 'Add ${widget.isPickup ? 'pickup' : 'drop'}'
        : 'Edit stop';
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xffd9deea),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xffffeee7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.isPickup
                            ? Icons.add_location_alt_outlined
                            : Icons.location_on_outlined,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.isPickup
                                ? 'Add a pickup along the route'
                                : 'Add a drop along the route',
                            style: const TextStyle(
                              color: Color(0xff66718a),
                              fontSize: AppTextStyles.captionSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, color: Color(0xff596681)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _Label('Location'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _location,
                  textCapitalization: TextCapitalization.words,
                  decoration: _input(
                    'Enter stop location',
                    Icons.place_outlined,
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter a location.' : null,
                ),
                const SizedBox(height: 13),
                const _Label('Quantity (T)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _input(
                    'Enter quantity in tonnes',
                    Icons.scale_outlined,
                  ),
                  validator: (v) {
                    final q = double.tryParse(v?.trim() ?? '');
                    return q == null || !q.isFinite || q <= 0
                        ? 'Enter a valid quantity greater than zero.'
                        : null;
                  },
                ),
                const SizedBox(height: 13),
                _Label(
                  widget.isPickup
                      ? 'Pickup contact (optional)'
                      : 'Consignee (optional)',
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedContact,
                  isExpanded: true,
                  decoration: _input(
                    widget.isPickup
                        ? 'Select pickup contact'
                        : 'Select consignee',
                    Icons.person_outline_rounded,
                  ),
                  hint: Text(
                    widget.isPickup
                        ? 'Select pickup contact'
                        : 'Select consignee',
                  ),
                  selectedItemBuilder: (context) => [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No contact'),
                    ),
                    for (final contact in _contacts)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          contact.split(' · ').first,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('No contact'),
                    ),
                    for (final contact in _contacts)
                      DropdownMenuItem<String>(
                        value: contact,
                        child: Text(contact, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(
                    () => _selectedContact = value == null || value.isEmpty
                        ? null
                        : value,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      if (_form.currentState!.validate()) {
                        Navigator.pop(
                          context,
                          StopEditorResult(
                            location: _location.text.trim(),
                            quantity: double.parse(_quantity.text.trim()),
                            contact: _selectedContact ?? '',
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.initial == null ? 'Save stop' : 'Save changes',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.navy,
      fontSize: AppTextStyles.labelSize,
      fontWeight: FontWeight.w700,
    ),
  );
}
