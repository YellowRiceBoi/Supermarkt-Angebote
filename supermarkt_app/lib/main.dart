import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// ==========================================
// DATENMODELLE
// ==========================================

class StorePrice {
  final String supermarket;
  final double price;

  const StorePrice({required this.supermarket, required this.price});
}

class Product {
  final String name;
  final double oldPrice;
  final List<StorePrice> prices;

  const Product({
    required this.name,
    required this.oldPrice,
    required this.prices,
  });
}

// Ein Eintrag in der Einkaufsliste besteht
// aus Produkt + ausgewähltem Supermarkt.
class ShoppingListItem {
  final Product product;
  final StorePrice storePrice;
  int quantity;

  ShoppingListItem({
    required this.product,
    required this.storePrice,
    this.quantity = 1,
  });
}

class ShoppingPlan {
  final List<ShoppingListItem> items;
  final Set<String> supermarkets;
  final double totalPrice;

  const ShoppingPlan({
    required this.items,
    required this.supermarkets,
    required this.totalPrice,
  });
}

// ==========================================
// APP
// ==========================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supermarkt Angebote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 199, 111, 23),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

// ==========================================
// HOMEPAGE
// ==========================================

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 0 = Angebote
  // 1 = Einkaufsliste
  int selectedPage = 0;

  // ==========================================
  // PRODUKTE
  // ==========================================

  final List<Product> products = const [
    Product(
      name: 'Coca-Cola 1,5 L',
      oldPrice: 1.49,
      prices: [
        StorePrice(supermarket: 'REWE', price: 0.99),
        StorePrice(supermarket: 'Lidl', price: 1.09),
        StorePrice(supermarket: 'Aldi', price: 1.19),
      ],
    ),

    Product(
      name: 'Barilla Spaghetti',
      oldPrice: 1.99,
      prices: [
        StorePrice(supermarket: 'REWE', price: 3.99),
        StorePrice(supermarket: 'Lidl', price: 0.99),
        StorePrice(supermarket: 'Aldi', price: 1.59),
      ],
    ),

    Product(
      name: 'Milka Schokolade',
      oldPrice: 1.39,
      prices: [
        StorePrice(supermarket: 'REWE', price: 3.99),
        StorePrice(supermarket: 'Lidl', price: 2.09),
        StorePrice(supermarket: 'Aldi', price: 0.89),
      ],
    ),
  ];

  // ==========================================
  // EINKAUFSLISTE
  // ==========================================

  final List<ShoppingListItem> shoppingList = [];

  // Produkt + Supermarkt hinzufügen
  void addToShoppingList(Product product, StorePrice storePrice) {
    setState(() {
      final existingIndex = shoppingList.indexWhere(
        (item) => item.product == product,
      );

      if (existingIndex == -1) {
        // Produkt ist noch nicht vorhanden
        shoppingList.add(
          ShoppingListItem(product: product, storePrice: storePrice),
        );
      } else {
        // Produkt ist schon vorhanden:
        // ausgewählten Supermarkt ändern
        shoppingList[existingIndex] = ShoppingListItem(
          product: product,
          storePrice: storePrice,
        );
      }
    });
  }

  // Eintrag entfernen
  void removeFromShoppingList(ShoppingListItem item) {
    setState(() {
      shoppingList.remove(item);
    });
  }

  void increaseQuantity(ShoppingListItem item) {
    setState(() {
      item.quantity++;
    });
  }

  void decreaseQuantity(ShoppingListItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        shoppingList.remove(item);
      }
    });
  }

  Map<String, double> calculateStoreTotals() {
    final Map<String, double> totals = {};

    for (final item in shoppingList) {
      for (final storePrice in item.product.prices) {
        totals.update(
          storePrice.supermarket,
          (currentTotal) => currentTotal + (storePrice.price * item.quantity),
          ifAbsent: () => storePrice.price * item.quantity,
        );
      }
    }

    return totals;
  }

  MapEntry<String, double>? findCheapestStore() {
    final totals = calculateStoreTotals();

    if (totals.isEmpty) {
      return null;
    }

    return totals.entries.reduce((a, b) => a.value < b.value ? a : b);
  }

  ShoppingPlan? createSingleStorePlan() {
    final cheapestStore = findCheapestStore();

    if (cheapestStore == null) {
      return null;
    }

    final storeName = cheapestStore.key;

    final List<ShoppingListItem> planItems = [];

    for (final item in shoppingList) {
      final storePrice = item.product.prices.firstWhere(
        (price) => price.supermarket == storeName,
      );

      planItems.add(
        ShoppingListItem(
          product: item.product,
          storePrice: storePrice,
          quantity: item.quantity,
        ),
      );
    }

    return ShoppingPlan(
      items: planItems,
      supermarkets: {storeName},
      totalPrice: cheapestStore.value,
    );
  }

  ShoppingPlan? findBestTwoStorePlan() {
    if (shoppingList.isEmpty) {
      return null;
    }

    // Alle vorhandenen Supermärkte sammeln
    final supermarkets = shoppingList
        .expand((item) => item.product.prices)
        .map((price) => price.supermarket)
        .toSet()
        .toList();

    ShoppingPlan? bestPlan;

    // Alle möglichen Paare ausprobieren
    for (int i = 0; i < supermarkets.length; i++) {
      for (int j = i + 1; j < supermarkets.length; j++) {
        final storeA = supermarkets[i];
        final storeB = supermarkets[j];

        final List<ShoppingListItem> planItems = [];
        double total = 0;

        // Jedes produkt wird gecheckt
        // Store A oder Store B
        for (final item in shoppingList) {
          final availablePrices = item.product.prices.where(
            (price) =>
                price.supermarket == storeA || price.supermarket == storeB,
          );

          if (availablePrices.isEmpty) {
            continue;
          }

          final cheapestPrice = availablePrices.reduce(
            (a, b) => a.price < b.price ? a : b,
          );

          planItems.add(
            ShoppingListItem(
              product: item.product,
              storePrice: cheapestPrice,
              quantity: item.quantity,
            ),
          );

          total += cheapestPrice.price * item.quantity;
        }

        final usedSupermarkets = planItems
            .map((item) => item.storePrice.supermarket)
            .toSet();

        final plan = ShoppingPlan(
          items: planItems,
          supermarkets: usedSupermarkets,
          totalPrice: total,
        );

        if (bestPlan == null || plan.totalPrice < bestPlan.totalPrice) {
          bestPlan = plan;
        }
      }
    }
    return bestPlan;
  }

  // ==========================================
  // HAUPTSEITE
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          selectedPage == 0 ? 'Supermarkt Angebote' : 'Einkaufsliste',
        ),
      ),

      body: selectedPage == 0 ? buildOffersPage() : buildShoppingListPage(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: (index) {
          setState(() {
            selectedPage = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Angebote',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Einkaufsliste',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ANGEBOTE
  // ==========================================

  Widget buildOffersPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktuelle Angebote',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                // Günstigsten Preis bestimmen
                final cheapestPrice = product.prices.reduce(
                  (a, b) => a.price < b.price ? a : b,
                );

                // Ist die günstigste Variante
                // schon auf der Einkaufsliste?
                final isInShoppingList = shoppingList.any(
                  (item) =>
                      item.product == product &&
                      item.storePrice.supermarket == cheapestPrice.supermarket,
                );

                return Card(
                  child: InkWell(
                    // Produkt antippen
                    onTap: () async {
                      final item = await Navigator.push<ShoppingListItem>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailPage(product: product),
                        ),
                      );

                      // Falls auf der Detailseite
                      // ein Markt ausgewählt wurde:
                      if (item != null) {
                        addToShoppingList(item.product, item.storePrice);
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(cheapestPrice.supermarket),

                                const SizedBox(height: 4),

                                Text(
                                  '${cheapestPrice.price.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Direkt den günstigsten
                          // Markt hinzufügen
                          IconButton(
                            icon: Icon(
                              isInShoppingList
                                  ? Icons.shopping_cart
                                  : Icons.add_shopping_cart,
                            ),
                            onPressed: () {
                              addToShoppingList(product, cheapestPrice);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EINKAUFSLISTE
  // ==========================================

  Widget buildShoppingListPage() {
    final totalPrice = shoppingList.fold<double>(
      0,
      (sum, item) => sum + (item.storePrice.price * item.quantity),
    );

    final storeTotals = calculateStoreTotals();

    final cheapestStore = findCheapestStore();
    final bestTwoStorePlan = findBestTwoStorePlan();
    final singleStorePlan = createSingleStorePlan();

    const double minimumSavingForExtraStore = 2.00;

    final double savingWithTwoStores =
        cheapestStore != null && bestTwoStorePlan != null
        ? cheapestStore.value - bestTwoStorePlan.totalPrice
        : 0;

    final bool recommendTwoStores =
        savingWithTwoStores >= minimumSavingForExtraStore;

    if (shoppingList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Deine Einkaufsliste ist leer.',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ==========================================
        // PRODUKTE
        // ==========================================

        ...shoppingList.map((item) {
          return Card(
            child: ListTile(
              title: Text(item.product.name),

              subtitle: Text(
                '${item.storePrice.supermarket} · '
                '${item.storePrice.price.toStringAsFixed(2)} €',
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      decreaseQuantity(item);
                    },
                  ),

                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      increaseQuantity(item);
                    },
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 8),

        // ==========================================
        // GESAMTSUMME
        // ==========================================
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gesamtsumme',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              Text(
                '${totalPrice.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // ==========================================
        // PREISVERGLEICH
        // ==========================================
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preisvergleich',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...storeTotals.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 17)),

                      Text(
                        '${entry.value.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // ==========================================
        // EINKAUF OPTIMIEREN
        // ==========================================
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✨ Einkauf optimieren',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // --------------------------
              // EIN GESCHÄFT
              // --------------------------
              if (cheapestStore != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendTwoStores ? 'Bequem' : '⭐ Empfohlen',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text('1 Geschäft'),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cheapestStore.key,
                              style: const TextStyle(fontSize: 18),
                            ),

                            Text(
                              '${cheapestStore.value.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (!recommendTwoStores && singleStorePlan != null) ...[
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.route),
                              label: const Text('Einkaufsplan anzeigen'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ShoppingPlanPage(plan: singleStorePlan),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // --------------------------
              // ZWEI GESCHÄFTE
              // --------------------------
              if (bestTwoStorePlan != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendTwoStores ? '⭐ Empfohlen' : 'Maximal sparen',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${bestTwoStorePlan.supermarkets.length} Geschäfte',
                        ),

                        const SizedBox(height: 12),

                        Text(
                          bestTwoStorePlan.supermarkets.join(' + '),
                          style: const TextStyle(fontSize: 18),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Gesamt'),

                            Text(
                              '${bestTwoStorePlan.totalPrice.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        if (cheapestStore != null) ...[
                          const SizedBox(height: 8),

                          Text(
                            recommendTwoStores
                                ? 'Der zusätzliche Laden spart mindestens '
                                      '${minimumSavingForExtraStore.toStringAsFixed(2)} €.'
                                : 'Für nur '
                                      '${savingWithTwoStores.toStringAsFixed(2)} € Ersparnis '
                                      'lohnt sich ein zusätzlicher Laden wahrscheinlich nicht.',

                            style: TextStyle(
                              fontSize: 13,

                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ersparnis'),

                              Text(
                                '${(cheapestStore.value - bestTwoStorePlan.totalPrice).toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (recommendTwoStores) ...[
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.route),
                              label: const Text('Einkaufsplan anzeigen'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShoppingPlanPage(
                                      plan: bestTwoStorePlan,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Extra Platz am Ende
        const SizedBox(height: 24),
      ],
    );
  }
}

// ==========================================
// PRODUKTDETAILSEITE
// ==========================================

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Kopie erstellen und nach Preis sortieren.
    final sortedPrices = [...product.prices]
      ..sort((a, b) => a.price.compareTo(b.price));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(product.name),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Preise nach Markt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: sortedPrices.length,

                separatorBuilder: (context, index) => const Divider(),

                itemBuilder: (context, index) {
                  final storePrice = sortedPrices[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,

                    leading: Icon(
                      index == 0
                          ? Icons.local_offer
                          : Icons.storefront_outlined,
                    ),

                    title: Text(storePrice.supermarket),

                    subtitle: index == 0
                        ? const Text('Günstigster Preis')
                        : null,

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${storePrice.price.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Genau diesen Markt
                        // auswählen.
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          tooltip: 'Zur Einkaufsliste',

                          onPressed: () {
                            Navigator.pop(
                              context,

                              ShoppingListItem(
                                product: product,
                                storePrice: storePrice,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// OPTIMALER EINKAUFSPLAN
// ==========================================

class ShoppingPlanPage extends StatefulWidget {
  final ShoppingPlan plan;

  const ShoppingPlanPage({super.key, required this.plan});

  @override
  State<ShoppingPlanPage> createState() => _ShoppingPlanPageState();
}

class _ShoppingPlanPageState extends State<ShoppingPlanPage> {
  final Set<ShoppingListItem> checkedItems = {};

  int get totalItemCount => widget.plan.items.length;

  int get checkedItemCount => checkedItems.length;

  @override
  Widget build(BuildContext context) {
    // Produkte nach Supermarkt gruppieren
    final Map<String, List<ShoppingListItem>> groupedItems = {};

    for (final item in widget.plan.items) {
      groupedItems.putIfAbsent(item.storePrice.supermarket, () => []);

      groupedItems[item.storePrice.supermarket]!.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Optimaler Einkaufsplan'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Dein Einkaufsplan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            '${widget.plan.supermarkets.length} Geschäfte',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          Text('$checkedItemCount von $totalItemCount Produkten erledigt'),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: totalItemCount == 0 ? 0 : checkedItemCount / totalItemCount,
          ),

          const SizedBox(height: 24),

          // Für jeden Supermarkt
          // einen eigenen Bereich erstellen.
          ...groupedItems.entries.map((storeEntry) {
            final store = storeEntry.key;

            final items = storeEntry.value;

            final subtotal = items.fold<double>(
              0,
              (sum, item) => sum + (item.storePrice.price * item.quantity),
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront),

                        const SizedBox(width: 8),

                        Text(
                          store,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Divider(),

                    // Produkte dieses Ladens
                    ...items.map((item) {
                      final itemTotal = item.storePrice.price * item.quantity;

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,

                        value: checkedItems.contains(item),

                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              checkedItems.add(item);
                            } else {
                              checkedItems.remove(item);
                            }
                          });
                        },

                        title: Text(
                          '${item.quantity}× ${item.product.name}',
                          style: TextStyle(
                            decoration: checkedItems.contains(item)
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,

                            color: checkedItems.contains(item)
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),

                        subtitle: Text(
                          '${item.storePrice.price.toStringAsFixed(2)} € pro Stück',
                        ),

                        secondary: Text(
                          '${itemTotal.toStringAsFixed(2)} €',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),

                    const Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Zwischensumme',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),

                        Text(
                          '${subtotal.toStringAsFixed(2)} €',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Gesamtpreis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gesamt',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  Text(
                    '${widget.plan.totalPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
