import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Column(
          children: <Widget> [
            Container(
              color: Color.fromARGB(255, 221, 249, 255),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: <Widget>[
                  Text('Home Screen')
                ],
              ),
            ),
            Spacer(),
            Container(
              color: Color.fromARGB(219, 173, 230, 189),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 159, 239, 167),
                        ),
                        onPressed: () {
                        },
                        child: Text(
                              "Feed",
                              style: DefaultTextStyle.of(
                                context,
                              ).style.apply(fontSizeFactor: 1),
                        )
                      )
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: <Widget> [
                        Spacer(),
                        SizedBox(
                            width: 150,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 159, 239, 167),
                              ),
                              onPressed: () {
                              },
                              child: Text(
                                    "Play",
                                    style: DefaultTextStyle.of(
                                      context,
                                    ).style.apply(fontSizeFactor: 1),
                              )
                            )
                        ),
                        Spacer(),
                        SizedBox(
                            width: 150,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 159, 239, 167),
                              ),
                              onPressed: () {
                              },
                              child: Text(
                                    "Clean",
                                    style: DefaultTextStyle.of(
                                      context,
                                    ).style.apply(fontSizeFactor: 1),
                              )
                            )
                        ),
                        Spacer(),
                      ]
                    )
                  ),
                  Padding(
                    padding:  const EdgeInsets.all(20),
                    child: Container(
                      color: Color.fromARGB(219, 246, 255, 226),
                      width: MediaQuery.of(context).size.width,
                      height: 150,
                      child: Column(
                        children: <Widget> [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget> [
                                Image.asset('images/hunger.png'),
                                SizedBox(
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    value: 0.5,
                                    backgroundColor: Color.fromARGB(255, 246, 255, 226),
                                    color: Color.fromARGB(255, 159, 239, 167),
                                  )
                                )
                              ]
                            )
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget> [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget> [
                                    Image.asset('images/enjoyment.png'),
                                    SizedBox(
                                      width: 100,
                                      child: LinearProgressIndicator(
                                        value: 0.5,
                                        backgroundColor: Color.fromARGB(255, 246, 255, 226),
                                        color: Color.fromARGB(255, 159, 239, 167),
                                      )
                                    )
                                  ]
                                ),
                                Gap(MediaQuery.of(context).size.width * 0.1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget> [
                                    Image.asset('images/hygiene.png'),
                                    SizedBox(
                                      width: 100,
                                      child: LinearProgressIndicator(
                                        value: 0.5,
                                        backgroundColor: Color.fromARGB(255, 246, 255, 226),
                                        color: Color.fromARGB(255, 159, 239, 167),
                                      )
                                    )
                                  ]
                                )
                              ]
                            )
                          )
                        ]
                      )
                    )
                  )
                ]
              ),
            )
          ]
      )
    );
    
  }
}