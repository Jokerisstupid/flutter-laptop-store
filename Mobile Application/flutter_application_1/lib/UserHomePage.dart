// lib/home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/ReviewPage.dart';
import 'package:flutter_application_1/cart_page.dart';
import 'package:flutter_application_1/profilepage.dart';
import 'details_page.dart';
import 'category_products_page.dart';
// at top of home.dart
import 'searchpage.dart';


/// ----------------- Helper functions to parse & format price -----------------
num _parsePrice(dynamic priceVal) {
  // Handle null, numeric, or string (with commas/currency) inputs robustly
  if (priceVal == null) return 0;
  if (priceVal is num) return priceVal;
  final cleaned = priceVal.toString().trim();
  // remove any non-digit except dot
  final onlyDigits = cleaned.replaceAll(RegExp(r'[^0-9.]'), '');
  return num.tryParse(onlyDigits) ?? 0;
}

String _formatWithCommas(int number) {
  final str = number.toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) buffer.write(',');
  }
  return buffer.toString().split('').reversed.join();
}

String _formatPrice(num price) {
  // If whole number show without decimals, else show two decimals
  if (price % 1 == 0) {
    return "Rs. ${_formatWithCommas(price.toInt())}";
  } else {
    final intPart = price.floor();
    final decimals = ((price - intPart) * 100).round().toString().padLeft(2, '0');
    return "Rs. ${_formatWithCommas(intPart)}.$decimals";
  }
}
/// ---------------------------------------------------------------------------

// ✅ Main Home Scaffold with Bottom Nav
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo.shade800,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ✅ Laptop categories
  final List<Map<String, String>> categories = const [
    {
      "label": "Gaming",
      "image":
          "https://res.cloudinary.com/df1sgdor0/image/upload/v1757768358/08_Legion_Pro_7i_10_ju19oo.png"
    },
    {
      "label": "Business",
      "image":
          "https://res.cloudinary.com/df1sgdor0/image/upload/v1757768479/SPZ1B-Platinum-13-BB-00_ppgqz4.jpg"
    },
    {
      "label": "Student",
      "image":
          "https://res.cloudinary.com/df1sgdor0/image/upload/v1757768534/media_2x1_feg0ed.jpg"
    },
    {
      "label": "Ultrabook",
      "image":
          "https://res.cloudinary.com/df1sgdor0/image/upload/v1757768663/1_513bc060-4133-441e-af4d-29ee0aeb1aae_c1yidk.jpg"
    },
    {
      "label": "MacBook",
      "image":
          "https://res.cloudinary.com/df1sgdor0/image/upload/v1757768694/Apple_new-macbookair-wallpaper-screen_11102020_big.jpg.large_uin3is.jpg"
    },
  ];

  final List<Map<String, dynamic>> quickOptions = const [
    {"icon": Icons.percent, "label": "Deals"},
    {"icon": Icons.laptop_mac, "label": "New Arrivals"},
    {"icon": Icons.star, "label": "Best Sellers"},
    {"icon": Icons.trending_up, "label": "Trending"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context),
            _buildOfferBanner(),
            _buildScrollableOptionIcons(),
            _buildSectionTitle("Shop by Category"),
            _buildCategoryScroll(context),
            _buildSectionTitle("Featured Laptops"),
            _buildPromoCards(context),
            _buildSectionTitle("All Laptops"),
            _buildFirestoreProducts(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Laptop Harbour Flagship Store\nShahrah-e-Faisal, Karachi",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReviewPage()),
                  );
                },
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Text("Search laptops & accessories",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferBanner() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.shade800,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Welcome to Laptop Harbour,\nget Rs. 2000 off your first laptop!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Image.network(
            "https://cdn-icons-png.flaticon.com/512/1048/1048953.png",
            height: 60,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.laptop, color: Colors.white, size: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableOptionIcons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          children: quickOptions.map((option) {
            return OptionIcon(
              icon: option['icon'],
              label: option['label'],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryScroll(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final label = categories[index]['label']!;
          final image = categories[index]['image']!;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryProductsPage(category: label),
                ),
              );
            },
            child: FoodCategory(image: image, label: label),
          );
        },
      ),
    );
  }

  Widget _buildPromoCards(BuildContext context) {
    final List<Map<String, dynamic>> promos = [
      {
        "title": "20% Off\nDell Alienware M15",
        "image":
            "https://res.cloudinary.com/df1sgdor0/image/upload/v1757768777/laptop-alienware-m15-r7-amd-pdp-hero_oemqnz.png",
        "price": 350000,
      },
      {
        "title": "15% Off\nHP Spectre x360",
        "image":
            "https://res.cloudinary.com/df1sgdor0/image/upload/v1757768856/c05903985_kentm6.png",
        "price": 280000,
      },
      {
        "title": "Deal\nMacBook Air M2 Rs. 230k",
        "image":
            "https://res.cloudinary.com/df1sgdor0/image/upload/v1757768904/mba13-skyblue-select-202503_jcuesb.jpg",
        "price": 230000,
      },
      {
        "title": "Hot Pick\nLenovo Legion 5 Pro",
        "image":
            "https://res.cloudinary.com/df1sgdor0/image/upload/v1757769019/24189880702_Legion5Pro16ARH7HStormGreyRGBBacklit_202201181128321666487803512_wc6cb3.png",
        "price": 300000,
      },
    ];

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          final promo = promos[index];
          final promoPriceNum = _parsePrice(promo['price']);
          final promoPriceText = _formatPrice(promoPriceNum);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailsPage(
                    docId: promo['title'] + index.toString(),
                    productName: promo['title'],
                    productImage: promo['image'],
                    price: promoPriceNum.round(),
                    description: '',
                  ),
                ),
              );
            },
            child: PromoCard(
              title: "${promo['title']}\n${promoPriceText}",
              imageUrl: promo['image'],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFirestoreProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text("No laptops available.")),
          );
        }

        final products = snapshot.data!.docs;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final productDoc = products[index];
            final data = productDoc.data() as Map<String, dynamic>;

            final name = data['name'] ?? 'Unnamed Laptop';
            final imageUrl = data['imageUrl'] ?? '';
            final dynamic priceVal = data['price'];
            final num priceNum = _parsePrice(priceVal);
            final String priceText = _formatPrice(priceNum);
            final category = data['category'] ?? 'Uncategorized';

            // pass rounded price to details (details expects int in your code base)
            final int priceForDetails = priceNum.round();

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailsPage(
                      docId: productDoc.id,
                      productName: name,
                      productImage: imageUrl,
                      price: priceForDetails,
                      description: data['description'] ?? '',
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 100),
                            )
                          : const Icon(Icons.image_not_supported, size: 100),
                    ),
                    const SizedBox(height: 8),
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(priceText,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 2),
                    Text(category,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// ✅ Search Page Implementation (Laptop Search)
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade800,
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search laptops...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase().trim();
            });
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No products found."));
          }

          final results = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) || category.contains(searchQuery);
          }).toList();

          if (results.isEmpty) {
            return const Center(child: Text("No matching laptops."));
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final data = results[index].data() as Map<String, dynamic>;
              final dynamic priceVal = data['price'];
              final num priceNum = _parsePrice(priceVal);
              final String priceText = _formatPrice(priceNum);

              return ListTile(
                leading: (data['imageUrl'] != null &&
                        data['imageUrl'].toString().isNotEmpty)
                    ? Image.network(data['imageUrl'], width: 50, height: 50)
                    : const Icon(Icons.laptop),
                title: Text(data['name'] ?? "Unnamed"),
                subtitle: Text(priceText),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsPage(
                        docId: results[index].id,
                        productName: data['name'] ?? 'Unnamed',
                        productImage: data['imageUrl'] ?? '',
                        price: priceNum.round(),
                        description: data['description'] ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Reusable Widgets (OptionIcon, FoodCategory, PromoCard)
class OptionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const OptionIcon({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.shade100,
            child: Icon(icon, color: Colors.indigo),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class FoodCategory extends StatelessWidget {
  final String image;
  final String label;
  const FoodCategory({super.key, required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ClipOval(
            child: Image.network(
              image,
              height: 50,
              width: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class PromoCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  const PromoCard({super.key, required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 60),
            ),
          ),
        ],
      ),
    );
  }
}
