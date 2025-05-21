import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentLocation = 'Loading...';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  String _selectedCategory = 'All';
  String _selectedSort = 'Popular';
  List<Map<String, dynamic>> _filteredEquipment = [...featuredEquipment];
  final List<Map<String, dynamic>> _filteredItems = [...nearbyItems];
  final List<Map<String, dynamic>> _wishlist = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Auto-scroll the page view
    _startAutoScroll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (_currentPage < 2) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        }
        _startAutoScroll();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentLocation = 'Location services disabled');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentLocation = 'Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(
            () => _currentLocation = 'Location permissions permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = '${position.latitude}, ${position.longitude}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _currentLocation = 'Error getting location');
    }
  }

  void _filterEquipment(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredEquipment = [...featuredEquipment];
      } else {
        _filteredEquipment = featuredEquipment
            .where((item) => item['category'] == category)
            .toList();
      }
    });
  }

  void _sortEquipment(String sortBy) {
    setState(() {
      _selectedSort = sortBy;
      switch (sortBy) {
        case 'Price: Low to High':
          _filteredEquipment.sort((a, b) => a['price'].compareTo(b['price']));
          break;
        case 'Price: High to Low':
          _filteredEquipment.sort((a, b) => b['price'].compareTo(a['price']));
          break;
        case 'Rating':
          _filteredEquipment.sort((a, b) => b['rating'].compareTo(a['rating']));
          break;
        case 'Distance':
          _filteredEquipment
              .sort((a, b) => a['distance'].compareTo(b['distance']));
          break;
        default:
          _filteredEquipment = [...featuredEquipment];
      }
    });
  }

  void _navigateToPayment(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'UZHAVUSEI',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_pin, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentLocation,
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search equipment, supplies...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search functionality
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Promotional Banner Carousel
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildPromoBanner(
                        index == 0
                            ? 'assets/banner3.jpg'
                            : index == 1
                                ? 'assets/banner2.jpg'
                                : 'assets/banner3.jpg',
                        index == 0
                            ? 'Special Offers'
                            : index == 1
                                ? 'New Arrivals'
                                : 'Seasonal Deals'),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions with additional options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(Icons.local_shipping, 'Rent', () {
                    _filterEquipment('Rent');
                  }),
                  _buildQuickAction(Icons.shopping_cart, 'Buy', () {
                    _filterEquipment('Buy');
                  }),
                  _buildQuickAction(Icons.sell, 'Sell', () {
                    _filterEquipment('Sell');
                  }),
                  _buildQuickAction(Icons.list, 'Listings', () {
                    _filterEquipment('All');
                  }),
                  _buildQuickAction(Icons.eco, 'Organic', () {
                    _filterEquipment('Organic');
                  }),
                ],
              ),
            ),

            // Category Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All'),
                    _buildCategoryChip('Tractors'),
                    _buildCategoryChip('Sprayers'),
                    _buildCategoryChip('Harvesters'),
                    _buildCategoryChip('Fertilizers'),
                    _buildCategoryChip('Seeds'),
                    _buildCategoryChip('Tools'),
                  ],
                ),
              ),
            ),

            // Sort Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButton<String>(
                    value: _selectedSort,
                    items: [
                      'Popular',
                      'Price: Low to High',
                      'Price: High to Low',
                      'Rating',
                      'Distance',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _sortEquipment(newValue);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Featured Equipment Section with enhanced functionality
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Equipment',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EquipmentListPage(
                                equipment: _filteredEquipment,
                                onItemSelected: _navigateToPayment,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filteredEquipment.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildEquipmentCard(
                            _filteredEquipment[index],
                            onTap: () =>
                                _navigateToPayment(_filteredEquipment[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Near You Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Near You',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all nearby items
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: nearbyItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildNearbyItem(nearbyItems[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(String imagePath, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Special Offer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get up to 30% off on selected items',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EquipmentDetailsPage(
                          item: featuredEquipment[_currentPage],
                          onAddToWishlist: _addToWishlist,
                          isInWishlist:
                              _isInWishlist(featuredEquipment[_currentPage]),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _toggleWishlist(featuredEquipment[_currentPage]);
                  },
                  icon: Icon(
                    _isInWishlist(featuredEquipment[_currentPage])
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: _selectedCategory == category,
        onSelected: (bool selected) {
          _filterEquipment(category);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
        labelStyle: TextStyle(
          color: _selectedCategory == category
              ? const Color(0xFF4CAF50)
              : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> equipment,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: equipment['imageUrl'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          equipment['rating'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_pin,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        equipment['distance'],
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        equipment['price'],
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Rent Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _navigateToPayment(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: item['imageUrl'],
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item['available'] == 'In Stock'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['available'],
                                style: TextStyle(
                                  color: item['available'] == 'In Stock'
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.store,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              item['seller'],
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_shipping,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              item['delivery'],
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['price'],
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['rating'].toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () => _navigateToPayment(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Buy Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_pin, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    item['distance'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    item['category'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToWishlist(Map<String, dynamic> item) {
    setState(() {
      if (!_isInWishlist(item)) {
        _wishlist.add(item);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to wishlist'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  void _removeFromWishlist(Map<String, dynamic> item) {
    setState(() {
      _wishlist.removeWhere((element) => element['title'] == item['title']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from wishlist'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    });
  }

  void _toggleWishlist(Map<String, dynamic> item) {
    if (_isInWishlist(item)) {
      _removeFromWishlist(item);
    } else {
      _addToWishlist(item);
    }
  }

  bool _isInWishlist(Map<String, dynamic> item) {
    return _wishlist.any((element) => element['title'] == item['title']);
  }
}

// Sample data
final List<Map<String, dynamic>> featuredEquipment = [
  {
    'title': 'John Deere Tractor',
    'distance': '2.5 miles away',
    'price': '₹1500/day',
    'rating': 4.8,
    'category': 'Tractors',
    'imageUrl':
        'https://public.readdy.ai/ai/img_res/0a80ccb4ec3e9e5231ed97f5d20096d6.jpg',
  },
  {
    'title': 'Boom Sprayer',
    'distance': '3.8 miles away',
    'price': '₹800/day',
    'rating': 4.6,
    'category': 'Sprayers',
    'imageUrl':
        'https://public.readdy.ai/ai/img_res/dc3d6f7aa43f5d901183b2f3da90273f.jpg',
  },
  {
    'title': 'Rotavator',
    'distance': '1.2 miles away',
    'price': '₹450/day',
    'rating': 4.5,
    'category': 'Tools',
    'imageUrl':
        'https://public.readdy.ai/ai/img_res/04c92b8dcfb87c037c057289448d7e13.jpg',
  },
  {
    'title': 'Organic Fertilizer',
    'distance': '0.8 miles away',
    'price': '₹250/bag',
    'rating': 4.7,
    'category': 'Fertilizers',
    'imageUrl':
        'https://public.readdy.ai/ai/img_res/1d9f6d09d32dd75629830b0f5835565b.jpg',
  },
  {
    'title': 'Paddy Seeds',
    'distance': '1.5 miles away',
    'price': '₹180/kg',
    'rating': 4.4,
    'category': 'Seeds',
    'imageUrl':
        'assets/paddy.jpg',
  },
];

final List<Map<String, dynamic>> nearbyItems = [
  {
    'title': 'Organic Fertilizer',
    'distance': '0.8 miles away',
    'price': '₹250/bag',
    'rating': 4.7,
    'category': 'Fertilizers',
    'description': 'Premium organic fertilizer for better crop yield',
    'seller': 'Green Farms',
    'available': 'In Stock',
    'delivery': 'Free Delivery',
    'imageUrl':
        'https://public.readdy.ai/ai/img_res/1d9f6d09d32dd75629830b0f5835565b.jpg',
  },
  {
    'title': 'Seeds - Paddy',
    'distance': '1.5 miles away',
    'price': '₹180/kg',
    'rating': 4.4,
    'category': 'Seeds',
    'description': 'High-quality paddy seeds with 95% germination rate',
    'seller': 'Agri Seeds Co.',
    'available': 'Limited Stock',
    'delivery': 'Free Delivery',
    'imageUrl':
        'assets/paddy.jpg',
  },
  {
    'title': 'Tractor Spare Parts',
    'distance': '2.1 miles away',
    'price': '₹1200/piece',
    'rating': 4.6,
    'category': 'Spare Parts',
    'description': 'Genuine tractor spare parts with warranty',
    'seller': 'Farm Equipment Hub',
    'available': 'In Stock',
    'delivery': 'Same Day Delivery',
    'imageUrl':
        'assets/parts.jpg',
  },
  {
    'title': 'Drip Irrigation Kit',
    'distance': '1.8 miles away',
    'price': '₹3500/kit',
    'rating': 4.8,
    'category': 'Irrigation',
    'description': 'Complete drip irrigation system for 1 acre',
    'seller': 'Water Tech Solutions',
    'available': 'In Stock',
    'delivery': 'Free Installation',
    'imageUrl':
        'assets/drip.jpg',
  },
];

// New Payment Page
class PaymentPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const PaymentPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Price: ${item['price']}',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption('Credit Card', Icons.credit_card),
            _buildPaymentOption('UPI', Icons.payment),
            _buildPaymentOption('Net Banking', Icons.account_balance),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement payment processing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment successful!'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Radio(
              value: title,
              groupValue: title,
              onChanged: (value) {},
              activeColor: const Color(0xFF4CAF50),
            ),
          ],
        ),
      ),
    );
  }
}

// New Equipment List Page
class EquipmentListPage extends StatelessWidget {
  final List<Map<String, dynamic>> equipment;
  final Function(Map<String, dynamic>) onItemSelected;

  const EquipmentListPage({
    super.key,
    required this.equipment,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Equipment'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: equipment.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => onItemSelected(equipment[index]),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: equipment[index]['imageUrl'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipment[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_pin,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      equipment[index]['distance'],
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  equipment[index]['price'],
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                equipment[index]['rating'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () => onItemSelected(equipment[index]),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                            child: const Text('Rent Now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// New Equipment Details Page
class EquipmentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onAddToWishlist;
  final bool isInWishlist;

  const EquipmentDetailsPage({
    super.key,
    required this.item,
    required this.onAddToWishlist,
    required this.isInWishlist,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Details'),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: Icon(
              isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () => onAddToWishlist(item),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: item['imageUrl'],
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        item['rating'].toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_pin, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        item['distance'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['description'] ?? 'No description available',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSpecification('Category', item['category']),
                  _buildSpecification('Price', item['price']),
                  _buildSpecification(
                      'Availability', item['available'] ?? 'In Stock'),
                  _buildSpecification(
                      'Delivery', item['delivery'] ?? 'Standard Delivery'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentPage(item: item),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Rent Now',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecification(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
