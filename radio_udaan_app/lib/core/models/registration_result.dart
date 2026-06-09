/// Response from `POST /events/{id}/registrations`.
class RegistrationResult {
  const RegistrationResult({required this.entryId, required this.status});

  final int entryId;
  final String status;
}
