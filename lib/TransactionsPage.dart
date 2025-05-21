import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final List<Transaction> _allTransactions = [
    Transaction(
      machineName: 'John Deere Tractor',
      imageUrl:
          'https://public.readdy.ai/ai/img_res/130ab5f09d630aac1fe8c1917779fdae.jpg',
      rentalDuration: '2 days',
      price: 4500.00,
      status: TransactionStatus.completed,
      location: 'Chennai, Tamil Nadu',
      owner: 'Rajesh Kumar',
      paymentMethod: 'UPI',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      machineName: 'Mahindra Harvester',
      imageUrl:
          'https://public.readdy.ai/ai/img_res/53c883660f2d8a56ab4a4d66e9f84643.jpg',
      rentalDuration: '1 day',
      price: 3500.00,
      status: TransactionStatus.pending,
      location: 'Coimbatore, Tamil Nadu',
      owner: 'Suresh Patel',
      paymentMethod: 'Bank Transfer',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      machineName: 'Kubota Tiller',
      imageUrl: 'assets/kubota.jpg',
      rentalDuration: '3 days',
      price: 2800.00,
      status: TransactionStatus.cancelled,
      location: 'Madurai, Tamil Nadu',
      owner: 'Mohan Singh',
      paymentMethod: 'Cash',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Transaction(
      machineName: 'Swaraj 744 FE Tractor',
      imageUrl: 'assets/Swaraj.jpeg',
      rentalDuration: '5 days',
      price: 6500.00,
      status: TransactionStatus.completed,
      location: 'Punjab, India',
      owner: 'Gurpreet Singh',
      paymentMethod: 'UPI',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Transaction(
      machineName: 'Mahindra JIVO 365 DI',
      imageUrl: 'assets/mahindra.jpg',
      rentalDuration: '2 days',
      price: 3200.00,
      status: TransactionStatus.pending,
      location: 'Haryana, India',
      owner: 'Vikram Singh',
      paymentMethod: 'Bank Transfer',
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Transaction(
      machineName: 'Sonalika DI 35 RX',
      imageUrl: 'assets/sona.jpg',
      rentalDuration: '3 days',
      price: 4200.00,
      status: TransactionStatus.completed,
      location: 'Uttar Pradesh, India',
      owner: 'Amit Kumar',
      paymentMethod: 'UPI',
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Transaction(
      machineName: 'Eicher 380 Super',
      imageUrl: 'assets/eicher.png',
      rentalDuration: '4 days',
      price: 5800.00,
      status: TransactionStatus.pending,
      location: 'Rajasthan, India',
      owner: 'Rajendra Singh',
      paymentMethod: 'Cash',
      date: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Transaction(
      machineName: 'Force Orchard Tractor',
      imageUrl: 'assets/Swaraj.jpeg',
      rentalDuration: '2 days',
      price: 3800.00,
      status: TransactionStatus.completed,
      location: 'Maharashtra, India',
      owner: 'Sanjay Patil',
      paymentMethod: 'UPI',
      date: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  List<Transaction> _filteredTransactions = [];
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _filteredTransactions = _allTransactions;
  }

  void _filterTransactions() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        final matchesSearch = transaction.machineName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.owner
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.location
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesFilter = _selectedFilter == 'all' ||
            (_selectedFilter == 'completed' &&
                transaction.status == TransactionStatus.completed) ||
            (_selectedFilter == 'pending' &&
                transaction.status == TransactionStatus.pending) ||
            (_selectedFilter == 'cancelled' &&
                transaction.status == TransactionStatus.cancelled);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterTransactions();
                });
              },
            ),
          ),
          if (_filteredTransactions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  return TransactionCard(
                      transaction: _filteredTransactions[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Transactions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                leading: Radio(
                  value: 'all',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value.toString();
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Completed'),
                leading: Radio(
                  value: 'completed',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value.toString();
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Pending'),
                leading: Radio(
                  value: 'pending',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value.toString();
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Cancelled'),
                leading: Radio(
                  value: 'cancelled',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value.toString();
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _filterTransactions();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      transaction.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.machineName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: ${transaction.rentalDuration}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Location: ${transaction.location}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(),
                  Text(
                    '₹${transaction.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Owner: ${transaction.owner}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Payment via ${transaction.paymentMethod}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy').format(transaction.date),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (transaction.status) {
      case TransactionStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case TransactionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Pending';
        break;
      case TransactionStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Machine', transaction.machineName),
                _buildDetailRow('Duration', transaction.rentalDuration),
                _buildDetailRow(
                    'Price', '₹${transaction.price.toStringAsFixed(2)}'),
                _buildDetailRow('Location', transaction.location),
                _buildDetailRow('Owner', transaction.owner),
                _buildDetailRow('Payment Method', transaction.paymentMethod),
                _buildDetailRow(
                  'Date',
                  DateFormat('dd MMM yyyy').format(transaction.date),
                ),
                const SizedBox(height: 16),
                _buildStatusBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class Transaction {
  final String machineName;
  final String imageUrl;
  final String rentalDuration;
  final double price;
  final TransactionStatus status;
  final String location;
  final String owner;
  final String paymentMethod;
  final DateTime date;

  Transaction({
    required this.machineName,
    required this.imageUrl,
    required this.rentalDuration,
    required this.price,
    required this.status,
    required this.location,
    required this.owner,
    required this.paymentMethod,
    required this.date,
  });
}

enum TransactionStatus { completed, pending, cancelled }
