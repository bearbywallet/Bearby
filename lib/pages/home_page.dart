import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Home'),
              Tab(text: 'History'),
              Tab(text: 'Browser'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(child: Text('Home Content')),
            Center(child: Text('History Content')),
            Center(child: Text('Browser Content')),
          ],
        ),
      ),
    );
  }
}
