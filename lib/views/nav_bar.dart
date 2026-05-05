import 'package:flutter/material.dart';

class MainNavBar extends StatelessWidget {
	const MainNavBar({
		super.key,
		required this.currentIndex,
		required this.onTap,
	});

	final int currentIndex;
	final ValueChanged<int> onTap;

	@override
	Widget build(BuildContext context) {
		return BottomNavigationBar(
			currentIndex: currentIndex,
			backgroundColor: const Color.fromARGB(219, 150, 242, 176),
			selectedItemColor: const Color.fromARGB(255, 77, 151, 86),
			onTap: onTap,
			items: const [
				BottomNavigationBarItem(
					icon: Icon(Icons.spa),
					label: 'Little Guy',
					backgroundColor: Color.fromARGB(219, 150, 242, 176),
				),
				BottomNavigationBarItem(
					icon: Icon(Icons.map),
					label: 'Map',
					backgroundColor: Color.fromARGB(219, 150, 242, 176),
				),
				BottomNavigationBarItem(
					icon: Icon(Icons.checkroom),
					label: 'Dress',
					backgroundColor: Color.fromARGB(219, 150, 242, 176),
				),
				BottomNavigationBarItem(
					icon: Icon(Icons.tag),
					label: 'Shop',
					backgroundColor: Color.fromARGB(219, 150, 242, 176),
				),
				BottomNavigationBarItem(
					icon: Icon(Icons.person),
					label: 'Profile',
					backgroundColor: Color.fromARGB(219, 150, 242, 176),
				),
			],
		);
	}
}

