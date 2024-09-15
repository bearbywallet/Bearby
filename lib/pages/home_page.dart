import 'package:flutter/material.dart';
import '../components/action_button.dart';

class HomePage extends StatelessWidget {
  // @override
  // Widget build(BuildContext context) {
  //   return SafeArea(
  //     child: Column(
  //       children: [
  //           Center(child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: [
  //               Text("home page"),
  //               CustomActionButton(
  //                 label: 'Send',
  //                 iconPath: 'assets/icons/send.svg',
  //                 onPressed: () {
  //                   print("test");
  //                 },
  //               ),
  //             ]
  //           ))
  //         ])
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ... other widgets
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomActionButton(
                label: 'Send',
                iconPath: 'assets/icons/send.svg',
                onPressed: () {
                  // Handle send action
                },
              ),
              CustomActionButton(
                label: 'Receive',
                iconPath: 'assets/icons/receive.svg',
                onPressed: () {
                  // Handle receive action
                },
              ),
              CustomActionButton(
                label: 'Swap',
                iconPath: 'assets/icons/swap.svg',
                onPressed: () {
                  // Handle swap action
                },
              ),
              CustomActionButton(
                label: 'Buy',
                iconPath: 'assets/icons/buy.svg',
                onPressed: () {
                  // Handle buy action
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
