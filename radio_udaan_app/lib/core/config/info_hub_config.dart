/// About tab payload from `GET /config` → `info_hub`.
class InfoHubConfig {
  const InfoHubConfig({
    this.donate = const DonateConfig(),
    this.social = const [],
  });

  factory InfoHubConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const InfoHubConfig();
    final socialRaw = json['social'];
    final social = <SocialLinkConfig>[];
    if (socialRaw is List) {
      for (final item in socialRaw) {
        if (item is Map<String, dynamic>) {
          final link = SocialLinkConfig.fromJson(item);
          if (link.url.isNotEmpty) social.add(link);
        }
      }
    }
    return InfoHubConfig(
      donate: DonateConfig.fromJson(
        json['donate'] as Map<String, dynamic>?,
      ),
      social: social,
    );
  }

  final DonateConfig donate;
  final List<SocialLinkConfig> social;
}

class DonateConfig {
  const DonateConfig({
    this.badge = '',
    this.headline = '',
    this.intro = '',
    this.accessibilityNote = '',
    this.upiId = '',
    this.qrImageUrl = '',
    this.bank = const DonateBankConfig(),
    this.razorpay = const RazorpayDonateConfig(),
  });

  factory DonateConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const DonateConfig();
    return DonateConfig(
      badge: json['badge']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      intro: json['intro']?.toString() ?? '',
      accessibilityNote: json['accessibility_note']?.toString() ?? '',
      upiId: json['upi_id']?.toString() ?? '',
      qrImageUrl: json['qr_image_url']?.toString() ?? '',
      bank: DonateBankConfig.fromJson(
        json['bank'] as Map<String, dynamic>?,
      ),
      razorpay: RazorpayDonateConfig.fromJson(
        json['razorpay'] as Map<String, dynamic>?,
      ),
    );
  }

  final String badge;
  final String headline;
  final String intro;
  final String accessibilityNote;
  final String upiId;
  final String qrImageUrl;
  final DonateBankConfig bank;
  final RazorpayDonateConfig razorpay;

  bool get hasContent =>
      headline.trim().isNotEmpty ||
      intro.trim().isNotEmpty ||
      upiId.trim().isNotEmpty ||
      qrImageUrl.trim().isNotEmpty ||
      bank.hasContent ||
      razorpay.enabled;
}

/// Public Razorpay slice from `info_hub.donate.razorpay`.
class RazorpayDonateConfig {
  const RazorpayDonateConfig({
    this.enabled = false,
    this.keyId = '',
    this.checkoutName = '',
    this.presetAmounts = const [],
    this.eightyGEnabled = false,
    this.eightyGPdfEmailEnabled = false,
  });

  factory RazorpayDonateConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const RazorpayDonateConfig();
    final presetsRaw = json['preset_amounts'];
    final presets = <int>[];
    if (presetsRaw is List) {
      for (final item in presetsRaw) {
        final amount = (item as num?)?.toInt();
        if (amount != null && amount > 0) presets.add(amount);
      }
    }
    return RazorpayDonateConfig(
      enabled: json['enabled'] == true,
      keyId: json['key_id']?.toString() ?? '',
      checkoutName: json['checkout_name']?.toString() ?? '',
      presetAmounts: presets,
      eightyGEnabled: json['eighty_g_enabled'] == true,
      eightyGPdfEmailEnabled: json['eighty_g_pdf_email_enabled'] == true,
    );
  }

  final bool enabled;
  final String keyId;
  final String checkoutName;
  final List<int> presetAmounts;
  final bool eightyGEnabled;
  final bool eightyGPdfEmailEnabled;
}

class DonateBankConfig {
  const DonateBankConfig({
    this.accountName = '',
    this.accountNumber = '',
    this.bankName = '',
    this.branchName = '',
    this.ifsc = '',
    this.micr = '',
    this.address = '',
  });

  factory DonateBankConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const DonateBankConfig();
    return DonateBankConfig(
      accountName: json['account_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      micr: json['micr']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }

  final String accountName;
  final String accountNumber;
  final String bankName;
  final String branchName;
  final String ifsc;
  final String micr;
  final String address;

  bool get hasContent =>
      accountName.trim().isNotEmpty ||
      accountNumber.trim().isNotEmpty ||
      bankName.trim().isNotEmpty;
}

class SocialLinkConfig {
  const SocialLinkConfig({
    required this.id,
    required this.label,
    required this.url,
  });

  factory SocialLinkConfig.fromJson(Map<String, dynamic> json) {
    return SocialLinkConfig(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  final String id;
  final String label;
  final String url;
}
