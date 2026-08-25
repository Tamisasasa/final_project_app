import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: currentIndex == 0 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => onTap(0),
            ),
            IconButton(
              icon: Icon(
                Icons.pets,
                color: currentIndex == 1 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => onTap(1),
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                color: currentIndex == 3 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}