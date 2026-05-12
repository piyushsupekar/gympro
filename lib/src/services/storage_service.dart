import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({required this.firebaseEnabled});

  final bool firebaseEnabled;

  Future<String> uploadProfilePicture(String uid, XFile file) async {
    if (!firebaseEnabled) {
      throw StateError('Firebase Storage is not configured.');
    }

    final ref = FirebaseStorage.instance.ref('profile_pictures/$uid.jpg');
    await ref.putData(await file.readAsBytes(), SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
