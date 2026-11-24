
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ZoomHamrahApp());
}

const blue = Color(0xFF1677FF);
const api = 'https://zoomhamrah.ir/wp-json/zoomhamrah/v1';

class ZoomHamrahApp extends StatelessWidget {
  const ZoomHamrahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'زوم همراه',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF172033),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: StorePage(),
      ),
    );
  }
}

class Product {
  final int id;
  final String name;
  final String price;
  final String image;
  final String permalink;
  final String stock;

  Product.fromJson(Map<String, dynamic> json)
      : id = int.tryParse('${json['id']}') ?? 0,
        name = '${json['name'] ?? 'محصول'}',
        price = '${json['price'] ?? '0'}',
        image = '${json['image'] ?? ''}',
        permalink = '${json['permalink'] ?? ''}',
        stock = '${json['stock_status'] ?? ''}';
}

class Category {
  final int id;
  final String name;
  final String image;
  final int count;

  Category.fromJson(Map<String, dynamic> json)
      : id = int.tryParse('${json['id']}') ?? 0,
        name = '${json['name'] ?? ''}',
        image = '${json['image'] ?? ''}',
        count = int.tryParse('${json['count']}') ?? 0;
}

class StoreApi {
  static Future<List<Product>> products({int? category}) async {
    final uri = Uri.parse('$api/products').replace(
      queryParameters: {
        'page': '1',
        'per_page': '30',
        if (category != null) 'category': '$category',
      },
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 25),
    );

    if (response.statusCode != 200) {
      throw Exception('خطای سرور: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data['success'] != true || data['products'] is! List) {
      throw Exception('پاسخ محصولات معتبر نیست');
    }

    return (data['products'] as List)
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Category>> categories() async {
    final response = await http.get(
      Uri.parse('$api/categories'),
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('خطای دریافت دسته‌بندی‌ها');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data['success'] != true || data['categories'] is! List) {
      throw Exception('پاسخ دسته‌بندی‌ها معتبر نیست');
    }

    return (data['categories'] as List)
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int tab = 0;
  int? selectedCategory;
  List<Product> products = [];
  List<Category> categories = [];
  final List<Product> cart = [];
  bool loading = true;
  String? error;
  final searchController = TextEditingController();
  String search = '';

  @override
  void initState() {
    super.initState();
    loadStore();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadStore() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        StoreApi.products(category: selectedCategory),
        StoreApi.categories(),
      ]);

      if (!mounted) return;
      setState(() {
        products = results[0] as List<Product>;
        categories = results[1] as List<Category>;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Product> get visibleProducts {
    if (search.trim().isEmpty) return products;
    return products
        .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
        .toList();
  }

  void openProduct(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetails(
        product: product,
        onAdd: () {
          setState(() => cart.add(product));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('به سبد خرید اضافه شد')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      categoriesPage(),
      cartPage(),
      accountPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shopping_bag_rounded, color: blue, size: 27),
            const SizedBox(width: 9),
            const Text(
              'زوم همراه',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: loadStore,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: blue))
          : error != null
              ? errorPage()
              : pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) {
          setState(() => tab = value);
        },
        backgroundColor: Colors.white,
        indicatorColor: blue.withOpacity(.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: blue),
            label: 'خانه',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'دسته‌بندی',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cart.isNotEmpty,
              label: Text('${cart.length}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: 'سبد خرید',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'حساب من',
          ),
        ],
      ),
    );
  }

  Widget errorPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 55, color: blue),
            const SizedBox(height: 18),
            const Text(
              'دریافت اطلاعات فروشگاه ناموفق بود',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(error ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: loadStore,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget homePage() {
    return RefreshIndicator(
      onRefresh: loadStore,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: searchController,
            onChanged: (value) => setState(() => search = value),
            decoration: InputDecoration(
              hintText: 'جستجوی محصول...',
              prefixIcon: const Icon(Icons.search, color: blue),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 155,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1677FF), Color(0xFF0750C7)],
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'به زوم همراه خوش آمدید',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'خرید آسان لوازم جانبی دیجیتال',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 12),
                Text(
                  'کیفیت، تنوع و خرید مطمئن',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          sectionTitle('دسته‌بندی محصولات', () {
            setState(() => tab = 1);
          }),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final category = categories[i];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category.id;
                      tab = 1;
                    });
                    loadStore();
                  },
                  child: SizedBox(
                    width: 85,
                    child: Column(
                      children: [
                        Container(
                          height: 67,
                          width: 67,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: category.image.isNotEmpty
                              ? Image.network(
                                  category.image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.category, color: blue),
                                )
                              : const Icon(Icons.category, color: blue),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          category.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          sectionTitle('محصولات فروشگاه', null),
          const SizedBox(height: 12),
          productGrid(visibleProducts),
        ],
      ),
    );
  }

  Widget categoriesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'دسته‌بندی‌ها',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        ...categories.map(
          (c) => Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: c.image.isNotEmpty
                  ? Image.network(
                      c.image,
                      width: 45,
                      height: 45,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.category, color: blue),
                    )
                  : const Icon(Icons.category, color: blue),
              title: Text(c.name),
              subtitle: Text('${c.count} محصول'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                setState(() => selectedCategory = c.id);
                loadStore();
                setState(() => tab = 0);
              },
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() => selectedCategory = null);
            loadStore();
            setState(() => tab = 0);
          },
          child: const Text('نمایش همه محصولات'),
        ),
      ],
    );
  }

  Widget cartPage() {
    return cart.isEmpty
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 65, color: blue),
                SizedBox(height: 12),
                Text(
                  'سبد خرید شما خالی است',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...cart.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  child: ListTile(
                    leading: productImage(p.image, 55),
                    title: Text(p.name, maxLines: 2),
                    subtitle: Text('${p.price} تومان'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => cart.removeAt(index)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 15),
              const Text(
                'برای تکمیل خرید، درگاه پرداخت و ثبت سفارش باید به اپ متصل شود.',
                textAlign: TextAlign.center,
              ),
            ],
          );
  }

  Widget accountPage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFE7F0FF),
              child: Icon(Icons.person, size: 42, color: blue),
            ),
            SizedBox(height: 15),
            Text(
              'حساب کاربری زوم همراه',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'ورود و ثبت‌نام با پیامک و رمز عبور در مرحله اتصال حساب کاربری فعال می‌شود.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title, VoidCallback? onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('مشاهده همه')),
      ],
    );
  }

  Widget productGrid(List<Product> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(25),
        child: Center(child: Text('محصولی پیدا نشد')),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .66,
      ),
      itemBuilder: (_, i) {
        final p = items[i];
        return GestureDetector(
          onTap: () => openProduct(p),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(child: productImage(p.image, 125)),
                ),
                const SizedBox(height: 9),
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '${p.price} تومان',
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() => cart.add(p));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('به سبد خرید اضافه شد'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    child: const Text('افزودن به سبد'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget productImage(String url, double size) {
    if (url.isEmpty) {
      return Icon(Icons.image_outlined, size: size * .55, color: Colors.grey);
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.image_not_supported_outlined, size: size * .55),
    );
  }
}

class ProductDetails extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductDetails({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: product.image.isEmpty
                    ? const Icon(Icons.image, size: 140, color: blue)
                    : Image.network(
                        product.image,
                        height: 190,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image, size: 140),
                      ),
              ),
              const SizedBox(height: 18),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${product.price} تومان',
                style: const TextStyle(
                  color: blue,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('افزودن به سبد خرید'),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
