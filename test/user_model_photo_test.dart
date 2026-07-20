import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/auth/data/model/user_model.dart';

void main() {
  test('user model membaca URL foto profil', () {
    final user = UserModel.fromJson('asatidz-1', {
      'name': 'Ustadz Ahmad',
      'nis': '1001',
      'email': '1001@khoirunnasyien.app',
      'role': 'asatidz',
      'phone': '08123456789',
      'photo_url': 'https://example.com/asatidz.jpg',
    });

    expect(user.photoUrl, 'https://example.com/asatidz.jpg');
  });
}
