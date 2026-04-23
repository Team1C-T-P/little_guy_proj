import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import 'package:flutter_flame_playground/views/shop_view.dart';
import '../widgets/button.dart';

class DressUp extends StatelessWidget {
  const DressUp({super.key});

  // automatically load images in a folder for shop use
  Future<List<String>> _loadImages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/images/hats/') &&
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
          // Top blue area containing the littleguy
          Expanded(
            flex: 3,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              child: Center(child: LittleGuy()),
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
                      itemBuilder: (context, index) => IconButton(
                        padding: EdgeInsets.all(8.0),
                        onPressed: () {
                          print('image was clicked');
                        },
                        icon: Image.asset(
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
          // bottom row, with the button to go to dress
          Stack(
            children: <Widget>[
              Container(child: Image.asset("assets/images/clover.png")),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SizedBox(
                  width: 10,
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FittedBox(
                      child: GreenButton(
                        buttonText: "Shop",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Shop()),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 18),
                child: Image.asset("assets/images/daisy.png"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
