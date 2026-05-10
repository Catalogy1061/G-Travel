import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class UserService {
  static final _supabase = Supabase.instance.client;
  static final _picker = ImagePicker();

  static User? get currentUser => _supabase.auth.currentUser;

  static String? get userAvatarUrl {
    return currentUser?.userMetadata?['avatar_url'];
  }

  static Future<String?> pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400, // Limita o tamanho conforme pedido
        maxHeight: 400,
        imageQuality: 70, // Diminui a qualidade para economizar espaço
      );

      if (image == null) return null;

      final userId = currentUser?.id;
      if (userId == null) return null;

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Upload para o Storage
      try {
        await _supabase.storage.from('avatars').upload(
              filePath,
              file,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
      } catch (uploadError) {
        print('Erro no upload para o Storage: $uploadError');
        // Se falhar o upload, não atualiza o metadata
        return null;
      }

      // Gera a URL pública
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // Atualiza o metadata do usuário
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      return publicUrl;
    } catch (e) {
      print('Erro geral no processo de avatar: $e');
      return null;
    }
  }

  static Future<bool> removeAvatar() async {
    try {
      // Remove do metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': null}),
      );
      return true;
    } catch (e) {
      print('Erro ao remover avatar: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Erro ao deslogar: $e');
    }
  }
}
