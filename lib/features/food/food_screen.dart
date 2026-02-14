import 'package:flutter/material.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  int _selectedTab = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Guidance'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search foods...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Category tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _CategoryTab(
                  label: 'Good',
                  color: Colors.green,
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 8),
                _CategoryTab(
                  label: 'Limit',
                  color: Colors.orange,
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                const SizedBox(width: 8),
                _CategoryTab(
                  label: 'Avoid',
                  color: Colors.red,
                  isSelected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Food list
          Expanded(
            child: _buildFoodList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    // If searching, search ALL categories
    if (_searchQuery.isNotEmpty) {
      final allResults = <Map<String, dynamic>>[];

      // Search good foods
      for (var food in _goodFoods) {
        if (food.toLowerCase().contains(_searchQuery)) {
          allResults
              .add({'name': food, 'category': 'Good', 'color': Colors.green});
        }
      }

      // Search limit foods
      for (var food in _limitFoods) {
        if (food.toLowerCase().contains(_searchQuery)) {
          allResults
              .add({'name': food, 'category': 'Limit', 'color': Colors.orange});
        }
      }

      // Search avoid foods
      for (var food in _avoidFoods) {
        if (food.toLowerCase().contains(_searchQuery)) {
          allResults
              .add({'name': food, 'category': 'Avoid', 'color': Colors.red});
        }
      }

      if (allResults.isEmpty) {
        return Center(
          child: Text(
            'No foods found for "$_searchQuery"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allResults.length,
        itemBuilder: (context, index) {
          final result = allResults[index];
          return _FoodItemWithCategory(
            name: result['name'] as String,
            category: result['category'] as String,
            color: result['color'] as Color,
          );
        },
      );
    }

    // If NOT searching, show current tab
    List<String> foods;
    Color categoryColor;

    switch (_selectedTab) {
      case 0:
        foods = _goodFoods;
        categoryColor = Colors.green;
        break;
      case 1:
        foods = _limitFoods;
        categoryColor = Colors.orange;
        break;
      case 2:
        foods = _avoidFoods;
        categoryColor = Colors.red;
        break;
      default:
        foods = [];
        categoryColor = Colors.grey;
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        return _FoodItem(
          name: foods[index],
          color: categoryColor,
        );
      },
    );
  }

  // GOOD FOODS
  static final List<String> _goodFoods = [
    'Almonds',
    'Almond Milk',
    'Amaranth',
    'Apples',
    'Apricots',
    'Artichokes',
    'Arugula',
    'Asparagus',
    'Avocado',
    'Bananas',
    'Barley',
    'Basmati Rice',
    'Beans',
    'Beets',
    'Bell Peppers',
    'Blackberries',
    'Blueberries',
    'Bok Choy',
    'Broccoli',
    'Brown Rice',
    'Bulgur',
    'Cabbage',
    'Canola Oil',
    'Carrots',
    'Cashews',
    'Cauliflower',
    'Cherries',
    'Chia Seeds',
    'Chicken Breast',
    'Chickpeas',
    'Cod',
    'Edamame',
    'Eggplant',
    'Flax Seeds',
    'Grapes',
    'Guava',
    'Haddock',
    'Halibut',
    'Kale',
    'Kidney Beans',
    'Kiwi',
    'Lentils',
    'Lima Beans',
    'Low-fat Milk (1%)',
    'Mango',
    'Millet',
    'Oat Bran',
    'Oats',
    'Okra',
    'Onions',
    'Oranges',
    'Papaya',
    'Pears',
    'Peas',
    'Pomegranate',
    'Pumpkin',
    'Quinoa',
    'Rye',
    'Salmon',
    'Sardines',
    'Soybeans',
    'Spinach',
    'Teff',
    'Tempeh',
    'Tofu',
    'Tomatoes',
    'Walnuts',
    'Whole-Grain Bread',
  ];

  // LIMIT FOODS
  static final List<String> _limitFoods = [
    'Air-Popped Popcorn',
    'Alcohol (Wine)',
    'Alcohol (Beer)',
    'Bagels',
    'Barbecue Sauce',
    'Beef (Lean Cuts)',
    'Cheese (Reduced-Fat)',
    'Chocolate (Dark 70%+)',
    'Coconut Milk (Light)',
    'Coconut Oil',
    'Cream Cheese (Light)',
    'Dark Chocolate (70%+)',
    'Eggs (Whole)',
    'Frozen Yogurt',
    'Granola Bars',
    'Honey',
    'Ice Cream (Light)',
    'Ketchup',
    'Lamb (Lean Cuts)',
    'Maple Syrup',
    'Mayonnaise (Light)',
    'Milk (1-2% Low-Fat)',
    'Muffins',
    'Non-Dairy Creamers',
    'Nuts (Small Portions)',
    'Organ Meats (Rarely)',
    'Palm Oil',
    'Pickles',
    'Pork Loin',
    'Pork Tenderloin',
    'Pretzels',
    'Plain Crackers',
    'Scallops',
    'Shellfish',
    'Shrimp',
    'Lobster',
    'Soy Products',
    'Sweetened Nut Milks',
    'Sweetened Yogurt',
    'Trail Mix (with Added Sugar)',
    'Vegetable Chips (Baked)',
    'White Bread',
    'White Pasta',
    'White Rice',
    'White Rolls',
  ];

  // AVOID FOODS
  static final List<String> _avoidFoods = [
    'Alfredo Sauce',
    'Animal Fats',
    'Bacon',
    'Bagels (White Flour)',
    'Biscuits',
    'Butter',
    'Cakes',
    'Candy Bars',
    'Cheddar Cheese',
    'Cheese Balls',
    'Cheese Puffs',
    'Chocolate Milk',
    'Chocolate Oil',
    'Cookies',
    'Corned Beef',
    'Deep-Fried Foods',
    'Deli Meats',
    'Doughnuts',
    'Drippings (Meat)',
    'Energy Drinks',
    'Fast Food',
    'Flavored Coffee (Sweetened)',
    'Flavored Tea (Sweetened)',
    'French Fries',
    'Fried Fish (Battered)',
    'Full-Fat Cream',
    'Full-Fat Milk',
    'Ghee',
    'Half and Half',
    'Ham',
    'Hot Dogs',
    'Instant Noodles',
    'Lamb (Fatty Cuts)',
    'Lamb Ribs',
    'Lard',
    'Margarine',
    'Onion Rings (Fried)',
    'Palm Kernel Oil',
    'Pepperoni',
    'Pork Belly',
    'Processed Chips',
    'Salami',
    'Sausage',
    'Smoked Meats',
    'Soda',
    'Soft Drinks',
    'Spare Ribs',
    'Sport Drinks',
    'Sugary Cereals',
    'Sweetened Fruit Drinks',
    'Whipped Cream',
  ];
}

class _FoodItemWithCategory extends StatelessWidget {
  final String name;
  final String category;
  final Color color;

  const _FoodItemWithCategory({
    required this.name,
    required this.category,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
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
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodItem extends StatelessWidget {
  final String name;
  final Color color;

  const _FoodItem({
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
