class AccountDraft {
  const AccountDraft({
    required this.name,
    required this.email,
    required this.acceptedTerms,
  });

  final String name;
  final String email;
  final bool acceptedTerms;

  bool get canSubmit => name.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      acceptedTerms;
}
