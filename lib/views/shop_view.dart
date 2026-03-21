import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../little%20guy.dart';
import '../widgets/button.dart';
import '../models/shop_database.dart';

class Shop extends StatefulWidget {
  const Shop({super.key});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  final ShopDatabase _shopDb = ShopDatabase();

  // Placeholder for user's coin balance, will be fetched from DB
  int _coinBalance = 0;
  List<Map<String, dynamic>> _items = [];
  Set<int> _ownedItemIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    // load user currency and shop items from the database
    // Assuming user ID 1 for now

    final currency = await _shopDb.getUserCurrency(1);
    final items = await _shopDb.getAllItems();
    final ownedIds = await _shopDb.getUserItems(1);

    setState(() {
      _coinBalance = currency;
      _items = items;
      _ownedItemIds = ownedIds.toSet();
      _isLoading = false;
    });
  }

  void _showPurchaseDialog(Map<String, dynamic> item) {
    final itemId = item['item_id'] as int;
    final itemName = item['item_name'] as String;
    final price = item['price'] as int;
    final alreadyOwned = _ownedItemIds.contains(itemId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase $itemName?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: $price coins'),
            SizedBox(height: 10),
            Text('Your Balance: $_coinBalance coins'),
            SizedBox(height: 10),
            if (alreadyOwned)
              Text(
                'You already own this item.',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (_coinBalance < price)
              Text(
                'You do not have enough coins to purchase this item.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          if (!alreadyOwned && _coinBalance >= price)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await _shopDb.purchaseItem(1, itemId);

                if (result == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Purchased $itemName!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadShopData(); // Refresh data after purchase
                } else if (result == 'already_owned') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You already own this item!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else if (result == 'insufficient_funds') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Not enough funds to purchase this item.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Buy'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(219, 150, 242, 176),
      body: Column(
        children: [
          // Top blue area containing the littleguy
          Expanded(
            flex: 3,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // balance the display
                  Text(
                    'Balance: $_coinBalance coins',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  LittleGuy(),
                ],
              ),
            ),
          ),

          // Area containing the items to choose
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(219, 246, 255, 226),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final itemId = item['item_id'] as int;
                    final isOwned = _ownedItemIds.contains(itemId);

                    return Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              IconButton(
                                padding: EdgeInsets.all(8),
                                onPressed: () => _showPurchaseDialog(item),
                                icon: Image.asset(
                                  item['image_path'] as String,
                                  fit: BoxFit.cover,
                                  color: isOwned ? Colors.grey : null,
                                  colorBlendMode: isOwned
                                      ? BlendMode.saturation
                                      : null,
                                ),
                              ),
                              if (isOwned)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Owned',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          isOwned ? 'OWNED' : '${item['price']} coins',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOwned ? Colors.green : Colors.black,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // bottom row, with the button to go to dress
          Stack(
            children: <Widget>[
              Container(child: Image.asset('assets/images/clover.png')),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SizedBox(
                  width: 10,
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FittedBox(
                      child: GreenButton(buttonText: "Dress", onPressed: () {}),
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 18),
                child: Image.asset('assets/images/daisy.png'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
