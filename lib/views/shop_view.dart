import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Shop extends StatelessWidget {
  const Shop({super.key});

  // automatically load images in a folder for shop use
  Future<List<String>> _loadImages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/images/') &&
              (path.endsWith('.png') || path.endsWith('.jpg')),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(219, 150, 242, 176),
      body: Column(
        children: [
          // Top blue area
          Expanded(
            flex: 3,
            child: Container(
              color: Color.fromARGB(255, 173, 232, 244),
              child: Center(
                child: Icon(Icons.pets, size: 80, color: Colors.grey),
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
                child: FutureBuilder<List<String>>(
                  future: _loadImages(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    // adds the images from the _loadiamges to the box
                    // in rows of four
                    return GridView.builder(
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Image.asset(
                          snapshot.data![index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Stack(
            children: <Widget>[
              Container(child: Image.asset("images/clover.png")),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SizedBox(
                  width: 10,
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FittedBox(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            159,
                            239,
                            167,
                          ),
                        ),
                        child: Text(
                          "Dress",
                          style: DefaultTextStyle.of(
                            context,
                          ).style.apply(fontSizeFactor: 1),
                        ),
                        onPressed: () => print("Test"),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 18),
                child: Image.asset("images/daisy.png"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
