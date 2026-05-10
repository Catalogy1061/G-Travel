import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:g_route_app/services/user_service.dart';
import 'package:g_route_app/screens/tabs/travel_history_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String get _userFirstName {
    final fullName = Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? "Viajante";
    return fullName.split(' ').first;
  }

  Future<void> _updateAvatar() async {
    final url = await UserService.pickAndUploadAvatar();
    if (url != null) {
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Avatar atualizado com sucesso!")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao carregar avatar. Verifique as permissões e o bucket 'avatars'."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    final success = await UserService.removeAvatar();
    if (success) {
      setState(() {});
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "FOTO DE PERFIL",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple, letterSpacing: 1),
            ),
            const SizedBox(height: 25),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryPurple),
              title: const Text("Alterar Foto", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _updateAvatar();
              },
            ),
            if (UserService.userAvatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text("Remover Foto", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = UserService.userAvatarUrl;
    
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 60),
                RepaintBoundary(
                  child: GestureDetector(
                    onTap: _showAvatarOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null 
                            ? const Icon(Icons.person, size: 85, color: AppTheme.primaryPurple)
                            : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _userFirstName,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Viajante Platinum",
                  style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 40),
                RepaintBoundary(child: _buildProfileStatRow()),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileOption(
                  Icons.history_rounded, 
                  "Histórico de Viagens", 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TravelHistoryScreen()),
                    );
                  },
                ),
                _buildProfileOption(Icons.favorite_outline_rounded, "Lugares Favoritos"),
                _buildProfileOption(Icons.payment_rounded, "Métodos de Pagamento"),
                _buildProfileOption(Icons.shield_outlined, "Segurança e Privacidade"),
                _buildProfileOption(Icons.share_rounded, "Convidar Amigos"),
                _buildProfileOption(Icons.help_outline_rounded, "Central de Ajuda"),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildProfileStatRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem("Viagens", "12"),
        Container(width: 1, height: 30, color: Colors.grey[200]),
        _buildStatItem("Países", "05"),
        Container(width: 1, height: 30, color: Colors.grey[200]),
        _buildStatItem("Pontos", "2.4k"),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[50]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryPurple, size: 24),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textGrey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        onTap: onTap,
      ),
    );
  }
}
