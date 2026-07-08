/// Razorpay donation order + verify responses from `/donate/*`.
class DonationOrderResult {
  const DonationOrderResult({
    required this.donationId,
    required this.orderId,
    required this.keyId,
    required this.amountPaise,
    required this.currency,
    required this.checkoutName,
    required this.paymentLink,
    required this.prefill,
  });

  factory DonationOrderResult.fromJson(Map<String, dynamic> json) {
    final prefillRaw = json['prefill'] as Map<String, dynamic>? ?? {};
    return DonationOrderResult(
      donationId: (json['donation_id'] as num?)?.toInt() ?? 0,
      orderId: json['order_id']?.toString() ?? '',
      keyId: json['key_id']?.toString() ?? '',
      amountPaise: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      checkoutName: json['checkout_name']?.toString() ?? '',
      paymentLink: json['payment_link']?.toString() ?? '',
      prefill: DonationPrefill.fromJson(prefillRaw),
    );
  }

  final int donationId;
  final String orderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final String checkoutName;
  final String paymentLink;
  final DonationPrefill prefill;
}

class DonationPrefill {
  const DonationPrefill({
    this.name = '',
    this.email = '',
    this.contact = '',
  });

  factory DonationPrefill.fromJson(Map<String, dynamic> json) {
    return DonationPrefill(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
    );
  }

  final String name;
  final String email;
  final String contact;
}

class DonationVerifyResult {
  const DonationVerifyResult({
    required this.success,
    this.donationId,
    this.status,
  });

  factory DonationVerifyResult.fromJson(Map<String, dynamic> json) {
    return DonationVerifyResult(
      success: json['success'] == true,
      donationId: (json['donation_id'] as num?)?.toInt(),
      status: json['status']?.toString(),
    );
  }

  final bool success;
  final int? donationId;
  final String? status;
}
