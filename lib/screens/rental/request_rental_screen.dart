import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../models/tool.dart';
import '../../models/rental.dart';
import '../../services/firestore_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class RequestRentalScreen extends StatefulWidget {
  final Tool tool;

  const RequestRentalScreen({
    super.key,
    required this.tool,
  });

  @override
  State<RequestRentalScreen> createState() => _RequestRentalScreenState();
}

class _RequestRentalScreenState extends State<RequestRentalScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _messageController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  double get _totalPrice {
    if (_startDate == null || _endDate == null) return 0;
    final days = _endDate!.difference(_startDate!).inDays + 1;
    return days * widget.tool.pricePerDay;
  }

  int get _days {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? (_startDate?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1))));
    
    final firstDate = isStart ? now : (_startDate?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1)));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if it's before new start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_startDate == null || _endDate == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);

    try {
      // Check availability
      final isAvailable = await _firestoreService.isToolAvailable(
        widget.tool.id,
        _startDate!,
        _endDate!,
      );

      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tool is not available for the selected dates'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Create rental request
      final rental = Rental(
        id: '',
        toolId: widget.tool.id,
        ownerId: widget.tool.ownerId,
        renterId: authState.user.id,
        startDate: _startDate!,
        endDate: _endDate!,
        totalPrice: _totalPrice,
        createdAt: DateTime.now(),
        message: _messageController.text.isEmpty ? null : _messageController.text,
      );

      await _firestoreService.createRental(rental);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental request sent!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Rental'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool info
            Card(
              child: ListTile(
                leading: widget.tool.images.isNotEmpty
                    ? Image.network(
                        widget.tool.images.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.handyman),
                title: Text(widget.tool.title),
                subtitle: Text('\$${widget.tool.pricePerDay.toStringAsFixed(2)}/day'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Date selection
            const Text(
              'Select Dates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _DatePickerCard(
                    label: 'Start Date',
                    date: _startDate,
                    formattedDate: _startDate != null ? dateFormat.format(_startDate!) : 'Select',
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerCard(
                    label: 'End Date',
                    date: _endDate,
                    formattedDate: _endDate != null ? dateFormat.format(_endDate!) : 'Select',
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Message
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message to Owner (Optional)',
                hintText: 'Hi! I\'d like to rent this tool for a home project...',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Price summary
            if (_days > 0) ...[
              const Text(
                'Price Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _PriceRow(
                label: '\$${widget.tool.pricePerDay.toStringAsFixed(2)} x $_days days',
                value: '\$${_totalPrice.toStringAsFixed(2)}',
              ),
              const Divider(),
              _PriceRow(
                label: 'Total',
                value: '\$${_totalPrice.toStringAsFixed(2)}',
                isBold: true,
              ),
            ],
          ],
        ),
      ),
      
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: (_startDate != null && _endDate != null && !_isLoading)
                ? _submitRequest
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _days > 0
                        ? 'Request for \$${_totalPrice.toStringAsFixed(2)}'
                        : 'Select Dates',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String formattedDate;
  final VoidCallback onTap;

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: date != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: date != null ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}