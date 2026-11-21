/// Dados básicos da conta Google conectada via Firebase Auth.
class AccountInfo {
  final String displayName;
  final String email;
  final String? photoUrl;
  final String uid;

  const AccountInfo({
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.uid,
  });

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'uid': uid,
      };

  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
        displayName: json['displayName'] as String? ?? 'Usuário',
        email: json['email'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        uid: json['uid'] as String? ?? '',
      );
}
