import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _friends = [
    {
      'id': 1,
      'name': 'Sarah Martinez',
      'username': '@sarahm',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'isOnline': true,
      'lat': 40.748817,
      'lng': -73.985428,
    },
    {
      'id': 2,
      'name': 'Mike Rodriguez',
      'username': '@miker',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'isOnline': true,
      'lat': 40.750817,
      'lng': -73.987428,
    },
    {
      'id': 3,
      'name': 'Jessica Chen',
      'username': '@jessicac',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'isOnline': false,
      'lat': 40.746817,
      'lng': -73.983428,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mapa de fondo
          _buildMapBackground(),
          // Botón de búsqueda flotante
          if (!_searchOpen) _buildSearchButton(),
          // Panel de búsqueda
          if (_searchOpen) _buildSearchPanel(),
          // Info card en la parte inferior
          if (!_searchOpen) _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Stack(
      children: [
        // Imagen de mapa de fondo
        Container(
          width: double.infinity,
          height: double.infinity,
          child: ImageWithFallback(
            imageUrl: 'https://images.unsplash.com/photo-1569163139394-de4798aa62b6',
            fit: BoxFit.cover,
          ),
        ),
        // Overlay oscuro
        Container(
          color: Colors.black.withOpacity(0.7),
        ),
        // Grid del mapa
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
        // Marcadores de amigos en el mapa
        ..._friends.asMap().entries.map((entry) {
          final index = entry.key;
          final friend = entry.value;
          return Positioned(
            top: 25 + (index % 3) * 20.0 * MediaQuery.of(context).size.height / 100,
            left: 20 + (index % 4) * 20.0 * MediaQuery.of(context).size.width / 100,
            child: _buildFriendMarker(friend),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFriendMarker(Map<String, dynamic> friend) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: AnimationController(
            duration: Duration(milliseconds: 600 + (friend['id'] as int) * 100),
          vsync: this,
        )..forward(),
        curve: Curves.elasticOut,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: friend['isOnline'] ? Colors.green : Colors.grey,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ImageWithFallback(
                imageUrl: friend['avatar'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 2,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _searchOpen = true;
          });
        },
        child: GlassCard(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Search users...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Column(
          children: [
            // Header de búsqueda
            _buildSearchHeader(),
            // Lista de resultados
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return _buildFriendCard(friend);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.white70),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _searchOpen = false;
                _searchController.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: ImageWithFallback(
                      imageUrl: friend['avatar'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (friend['isOnline'])
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    friend['username'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildActionButton(Icons.location_on, AppColors.primary),
                const SizedBox(width: 8),
                _buildActionButton(Icons.chat, AppColors.secondary),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildInfoCard() {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Friends Nearby',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_friends.where((f) => f['isOnline']).length} friends online',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Search All',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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