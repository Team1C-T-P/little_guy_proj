import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

/// Profile screen displaying user information, pets, and costumes
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  final TextEditingController _petController = TextEditingController();
  final TextEditingController _costumeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _petController.dispose();
    _costumeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _addPet() async {
    if (_petController.text.trim().isEmpty) return;
    
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.addPet(user.uid, _petController.text.trim());
      _petController.clear();
      await _loadUserProfile();
    }
  }

  Future<void> _addCostume() async {
    if (_costumeController.text.trim().isEmpty) return;
    
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.addCostume(user.uid, _costumeController.text.trim());
      _costumeController.clear();
      await _loadUserProfile();
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile'),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _userProfile!.photoUrl != null
                            ? NetworkImage(_userProfile!.photoUrl!)
                            : null,
                        child: _userProfile!.photoUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile!.displayName ?? 'User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userProfile!.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Pets Section
              _buildSection(
                title: 'My Pets',
                icon: Icons.pets,
                items: _userProfile!.pets,
                controller: _petController,
                onAdd: _addPet,
                hintText: 'Add a pet...',
              ),
              const SizedBox(height: 24),
              
              // Costumes Section
              _buildSection(
                title: 'My Costumes',
                icon: Icons.checkroom,
                items: _userProfile!.costumes,
                controller: _costumeController,
                onAdd: _addCostume,
                hintText: 'Add a costume...',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Add new item input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: hintText,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => onAdd(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onAdd,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // List of items
                items.isEmpty
                    ? const Text(
                        'No items yet. Add one above!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(items[index]),
                            dense: true,
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
