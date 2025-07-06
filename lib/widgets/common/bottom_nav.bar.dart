import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.black54,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile', // test1
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat', // test2
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings', // test3
        ),
      ],
    );
  }
}
