import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import 'package:flutter_flame_playground/views/shop_view.dart';
import 'package:flutter_flame_playground/widgets/button.dart';

class DressUp extends StatelessWidget {
  const DressUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const LittleGuy(),
          // Gives twice the space between Middle and End than Begin and Middle.
          Spacer(flex: 2),
          Container(
            color: Color.fromARGB(219, 173, 230, 189),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    color: Color.fromARGB(219, 246, 255, 226),
                    width: MediaQuery.of(context).size.width,
                    height: 250,
                    child: GridView.builder(
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        return Image.asset('images/hat.png');
                      },
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
                            child: GreenButton(
                              buttonText: "Shop",
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const Shop(),
                                  ),
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
                      child: Image.asset("images/daisy.png"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
