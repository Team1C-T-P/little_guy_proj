import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/views/community_view.dart';
import 'package:flutter_flame_playground/views/profile_view.dart';
import 'package:flutter_flame_playground/views/test_view.dart';
import 'package:flutter_flame_playground/widgets/button.dart';

class RoutesView extends StatefulWidget {
  const RoutesView({super.key});

  @override
  State<RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<RoutesView> {
  final List<String> _savedRoutes = ['Campus', 'Gym', 'Shop'];

  Future<void> _showCreateRouteDialog() async {
    final routeNameController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final routeName = routeNameController.text.trim();
            final canSave = routeName.isNotEmpty;

            return AlertDialog(
              title: const Text('Create route'),
              content: TextField(
                controller: routeNameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Route name'),
                onChanged: (_) => setDialogState(() {}),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canSave
                      ? () {
                          setState(() {
                            _savedRoutes.add(routeName);
                          });
                          Navigator.pop(dialogContext);
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    routeNameController.dispose();
  }

  Future<void> _showStartRouteDialog(String routeName) async {
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Start route?'),
          content: Text('Do you want to start "$routeName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );

    if (shouldStart == true && mounted) {
      Navigator.pop(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 213, 248, 255),
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: const Color.fromARGB(255, 213, 248, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Test Screen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.diversity_1),
            tooltip: 'Community',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommunityScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GreenButton(
                buttonText: 'Create Route',
                onPressed: _showCreateRouteDialog,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved Routes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _savedRoutes.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, thickness: 1),
                          itemBuilder: (context, index) {
                            final routeName = _savedRoutes[index];

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              leading: const Icon(
                                Icons.route,
                                color: Colors.green,
                              ),
                              title: Text(routeName),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Delete route',
                                onPressed: () {
                                  setState(() {
                                    _savedRoutes.removeAt(index);
                                  });
                                },
                              ),
                              onTap: () => _showStartRouteDialog(routeName),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
