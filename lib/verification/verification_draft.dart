import 'dart:io';

class VerificationDraft {
  String? fullName;
  String? aboutYou;
  String gender = 'MALE';
  File? nationalIdFront;
  File? nationalIdBack;
  File? facePhoto;

  static final VerificationDraft instance = VerificationDraft();

  void clear() {
    fullName = null;
    aboutYou = null;
    gender = 'MALE';
    nationalIdFront = null;
    nationalIdBack = null;
    facePhoto = null;
  }
}
