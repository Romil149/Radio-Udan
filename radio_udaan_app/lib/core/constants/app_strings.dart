/// User-visible copy for the mobile app (English).
///
/// Centralising strings keeps tone consistent and simplifies localization later.
abstract final class AppStrings {
  static const String appName = 'Radio Udaan';

  // Bootstrap / splash (Stitch Udaan Core)
  static const String bootstrapLoading = 'READY TO LAUNCH';
  static const String splashTagline = '...A flight of life';
  static const String splashA11yBadge = 'Optimized for screen readers';
  static const String bootstrapOffline =
      'Could not connect to the server. Check your network and try again.';
  static const String retry = 'Retry';

  // Auth
  static const String signInTitle = 'Sign in';
  static const String loginWelcome =
      'Welcome back. Let\'s get you listening.';
  static const String loginMobileIntro =
      'Sign in with your mobile number and password.';
  static const String loginEmailIntro =
      'Sign in with your verified email and password.';
  static const String loginEmailVerifiedNote =
      'Only verified email addresses can sign in here.';
  static const String signInWithEmail = 'Login using email';
  static const String signInWithMobile = 'Login using mobile';
  static const String loginMobileLabel = 'Mobile Number';
  static const String loginMobileHint = 'Enter your details';
  static const String loginPasswordHint = 'Enter your password';
  static const String loginButton = 'Login';
  static const String signInPasswordIntro =
      'Sign in with your email or mobile number and password.';
  static const String signInWithOtp = 'Login with OTP';
  static const String signInWithPassword = 'Sign in with password';
  static const String otpSendCode = 'Send code';
  static const String signInIntro =
      'Choose your country code and mobile number. We will send a one-time code by SMS.';
  static const String signIn = 'Sign in';
  static const String identifierLabel = 'Email or mobile';
  static const String identifierHint = 'you@example.com or mobile number';
  static const String identifierInvalid =
      'Enter a valid email address or mobile number.';
  static const String passwordLabel = 'Password';
  static const String passwordRequired = 'Enter your password.';
  static const String passwordTooShort =
      'Password is too short. Check the minimum length in settings.';
  static const String passwordMismatch = 'Passwords do not match.';
  static const String confirmPasswordLabel = 'Confirm password';
  static const String forgotPasswordLink = 'Forgot Password?';
  static const String dontHaveAccount = 'Don\'t have an account?';
  static const String registerHere = 'Register Here';
  static const String noAccountLink = 'Create an account';
  static const String hasAccountLink = 'Already have an account? Sign in';
  static const String registerTitle = 'Create Account';
  static const String registerIntro =
      'Join our inclusive community and experience accessible radio like never before.';
  static const String registerNameHint = 'Enter your full name';
  static const String registerMobileHint = '98765 43210';
  static const String registerPasswordHint = 'Min. 8 characters';
  static const String registerConfirmHint = 'Repeat your password';
  static const String registerButton = 'Register';
  static const String hasAccountPrompt = 'Already have an account?';
  static const String signInHere = 'Sign In here';
  static const String registerA11yTitle = 'Accessibility Assist';
  static const String registerA11yBody =
      'This form is optimized for screen readers and keyboard navigation. '
      'Large touch targets (64px+) and high contrast (4.5:1+) are enabled. '
      'Use Tab to move between fields.';
  static const String registerCopyright =
      '© 2024 Radio Udaan - Voice of Empowerment';
  static const String nameLabel = 'Full Name';
  static const String nameRequired = 'Enter your name.';
  static const String emailLabel = 'Email';
  static const String emailHint = 'you@example.com';
  static const String emailInvalid = 'Enter a valid email address.';
  static const String createAccount = 'Create account';
  static const String verifyEmailTitle = 'Verify email';
  static const String verifyEmailIntro =
      'Enter the 6-digit code we sent to your email.';
  static const String verificationCodeLabel = 'Verification code';
  static const String verificationCodeHint =
      'Enter the 6-digit code from your email.';
  static const String verificationCodeResent =
      'A new verification code has been sent.';
  static const String forgotPasswordTitle = 'Forgot Password';
  static const String forgotPasswordIntro =
      'Reset your password using your email or mobile number.';
  static const String forgotPasswordChannelEmail = 'Email';
  static const String forgotPasswordChannelPhone = 'Mobile';
  static const String forgotPasswordChannelSemantics =
      'Choose email or mobile for password reset';
  static const String forgotPasswordEmailHint = 'Enter your email';
  static const String forgotPasswordEmailNote =
      'Reset codes are sent only to your verified email. '
      'Sign in and verify your email first if you have not already.';
  static const String forgotPasswordPhoneNote =
      'We\'ll text a one-time code to your verified mobile number, '
      'then you can choose a new password.';
  static const String resetPasswordButton = 'Reset Password';
  static const String backToLogin = 'Back to login';
  static const String forgotPasswordHelpBody =
      'Need help? Call our 24/7 accessible support line or use the '
      'screen reader shortcut Alt + H.';
  static const String forgotPasswordSuccess =
      'If an account exists, reset instructions have been sent.';
  static const String sendResetLink = 'Send reset instructions';
  static const String resetPasswordTitle = 'Reset password';
  static const String resetPasswordIntro = 'Choose a new password.';
  static const String resetPassword = 'Reset password';
  static const String resetTokenLabel = 'Reset link token';
  static const String resetTokenRequired = 'Enter the reset link token from your email.';
  static const String resetEmailCodeRequired =
      'Enter the 6-digit code from your email.';
  static const String resetPasswordSuccess =
      'Password updated. You can sign in now.';
  static const String mobileNumberLabel = 'Mobile number';
  static const String mobileNumberHint = '+91 98765 43210';
  static const String sendCode = 'Send code';
  static const String verifyTitle = 'Verify code';
  static const String otpEnterTitle = 'Enter OTP';
  static const String verifyIdentityTitle = 'Verify Identity';
  static const String verifyIdentityIntro =
      'We\'ve sent a 6-digit security code to your registered mobile number ending in';
  static const String verifyButton = 'Verify';
  static const String otpHavingTrouble = 'Having trouble?';
  static const String contactSupport = 'Contact Support';
  static const String otpSentIntro =
      'We have sent a 6-digit code to your mobile number';
  static const String otpLoginButton = 'LOGIN';
  static const String otpResendLabel = 'Resend OTP';
  static const String otpWaitPrompt = 'Didn\'t receive the code? Wait ';
  static String otpWaitTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static const String verifyIntroManual =
      'Enter the code sent to your number. Type the digits manually — the app does not read SMS.';
  static const String verifyDevHint =
      'Development build: code may be prefilled from the server.';
  static const String otpLabel = 'Verification code';
  static const String verifyAndContinue = 'Verify and continue';
  static const String verifyEmailLink = 'Verify email';
  static const String verificationCodeRequired =
      'Enter the 6-digit verification code.';
  static String verifyEmailSentTo(String email) =>
      'We sent a 6-digit code to $email.';

  // Auth semantics / accessibility
  static const String backButton = 'Back';
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';
  static const String accountIcon = 'Account';
  static const String resetPasswordHero = 'Reset password';
  static const String verifyIdentityHero = 'Verify your identity';
  static const String secureVerificationHero = 'Secure verification';
  static const String appLogoSemantics = 'Radio Udaan logo';
  static String brandingLogoSemantics(String appName) => '$appName logo';
  static const String otpPinRowLabel = 'Verification code';
  static String otpPinRowSmsHint(int length) =>
      'Enter $length digits from your SMS';
  static String otpPinRowEmailHint(int length) =>
      'Enter $length digits from your email';
  static const String otpPinRowEmpty = 'Empty';
  static String otpPinRowValue(String code) => '$code entered';

  static const String registrationIncomplete =
      'Registration could not be completed.';
  static String passwordMinHint(int minLength) =>
      'Min. $minLength characters';
  static const String otpCodeIncomplete =
      'Enter the full code from your SMS.';
  static const String verificationIncomplete =
      'Verification did not complete. Try again.';
  static String resetPasswordSmsIntro(String phone) =>
      'Choose a new password for $phone.';
  static String profileSignedInSemantics({
    String? name,
    String? email,
    String? phone,
  }) {
    final parts = <String>[
      if (name != null && name.isNotEmpty) name,
      if (email != null && email.isNotEmpty) email,
      if (phone != null && phone.isNotEmpty) phone,
    ];
    if (parts.isEmpty) return profile;
    return '$profile, signed in as ${parts.join(', ')}';
  }
  static const String phoneFieldLabel = 'Mobile number';
  static const String phoneFieldHelper =
      'Choose your country code, then enter your mobile number without the leading zero.';
  static const String phoneNationalHint = '98765 43210';
  static const String phoneCountrySearchHint = 'Search country';
  static const String phoneCountryPickerTitle = 'Select country code';
  static const String phoneCountryFavorites = 'Favorites';
  static const String phoneNationalFieldSemantics =
      'Mobile number without country code';
  static String phoneCountryCodeSemantics({
    required String countryName,
    required String dialCode,
  }) =>
      'Country code, $countryName, plus $dialCode. Double tap to change country.';
  static const String phoneInvalid =
      'Enter a valid mobile number for the country you selected.';
  static const String phoneFieldHint =
      'International mobile with country code, e.g. +91 98765 43210 or +1 555 123 4567';
  static const String otpDigitHint =
      'Enter all digits from the SMS; up to 8 digits';
  static const String semanticsLoading = 'Loading…';
  static const String sendingCodePleaseWait = 'Sending code, please wait';
  static const String verifyingCodePleaseWait = 'Verifying code, please wait';
  static const String resendCode = 'Resend code';
  static String resendInSeconds(int seconds) => 'Resend in ${seconds}s';
  static const String resendingCodePleaseWait =
      'Sending a new code, please wait';
  static const String otpResentSuccess =
      'A new code has been sent. Check your SMS.';
  static const String mainNavigation = 'Main navigation';
  static const String eventsLoading = 'Loading events';
  static const String eventsPageTitle = 'Register For Events';
  static const String eventsPageIntro =
      'Join our vibrant community in upcoming accessible live streams and workshops.';
  static const String eventsRegisterNow = 'Register Now';
  static const String eventsRegistrationClosed = 'Registration closed';
  static String eventCardSemantics({
    required String title,
    String? schedule,
    String? badge,
    bool registrationOpen = true,
  }) {
    return [
      title,
      if (badge != null && badge.isNotEmpty) badge,
      if (schedule != null && schedule.isNotEmpty) schedule,
      if (!registrationOpen) eventsRegistrationClosed,
    ].join(', ');
  }
  static const String libraryLoading = 'Loading library';
  static const String submittingRegistrationPleaseWait =
      'Submitting registration, please wait';

  // Tabs
  static const String tabRadio = 'Live Radio';
  static const String tabLibrary = 'Library';
  static const String tabEvents = 'Events';
  static const String tabMore = 'More';

  // Radio
  static const String radioIntro = ' ';
  static const String radioShowTitle = 'Udaan Morning Show';
  static const String radioShowSubtitle = 'with RJ Karan & RJ Meera';
  static const String radioWithHostsPrefix = 'with ';
  static const String radioWhatsappUrlFallback = '#';
  static const String radioShareTextFallback = 'Listen to Radio Udaan live!';
  static const String shareFailed = 'Could not open share sheet';
  static const String shareUnavailable = 'Sharing is not available on this device';
  static const String shareCopied = 'Share message copied to clipboard';
  static const String radioPlay = 'Play Live Stream';
  static const String radioPlayOnAir = 'Play Live Stream. On air: {show}';
  static const String radioPause = 'Pause';
  static const String radioStop = 'Stop Live Stream';
  static const String radioConnecting = 'Connecting…';
  static const String radioPlaying = 'Live radio is playing';
  static const String radioStopped = 'Live radio stopped';
  static const String radioPlaybackError = 'Could not play live radio';
  static const String radioAudioUnavailable =
      'Live radio could not start on this device. Check your internet connection and try Play again.';
  static const String radioStreamMissing =
      'Stream URL is not configured on the server.';
  static const String radioVolume = 'Volume';
  static const String joinWhatsAppChannel = 'Join WhatsApp Channel';
  static const String share = 'Share';
  static const String schedule = 'Schedule';
  static const String unknown = 'Unknown';
  static const String radioScheduleTitle = 'Radio schedule';
  static const String radioScheduleOnAir = 'On air now';
  static const String radioScheduleRepeat = 'Repeat';
  static const String radioScheduleEmpty = 'No schedule available right now.';
  static const String radioScheduleFailed =
      'Could not load the schedule. Please try again.';
  static const String radioUpcomingSegments = 'Upcoming segments';
  static const String radioUpcomingNone = 'No upcoming segments found.';
  static const String radioViewFullSchedule = 'View full schedule';
  static const String radioFavoriteAdd = 'Add to favorites';
  static const String radioFavoriteRemove = 'Remove from favorites';
  static const String radioFavorite = 'Favorite';
  static const String radioShareLive = 'Share live';
  static const String joinTheDiscussion = 'Join the discussion';

  static String radioFavoriteButtonLabel({
    required String showTitle,
    required bool isFavorite,
  }) =>
      isFavorite
          ? 'Remove $showTitle from favorites'
          : 'Add $showTitle to favorites';

  static String radioFavoriteAnnouncement({
    required String showTitle,
    required bool added,
  }) =>
      added
          ? 'Added $showTitle to favorites'
          : 'Removed $showTitle from favorites';

  static String radioUpcomingSegmentsLabel({
    required String segmentTitle,
    String subtitle = '',
  }) {
    final parts = <String>[
      radioUpcomingSegments,
      segmentTitle,
      if (subtitle.isNotEmpty) subtitle,
      radioViewFullSchedule,
    ];
    return parts.join(', ');
  }

  static String radioScheduleSegmentSemantics({
    required String title,
    String time = '',
    String hosts = '',
    bool onAir = false,
  }) {
    final parts = <String>[
      if (onAir) radioScheduleOnAir,
      title,
      if (time.isNotEmpty) time,
      if (hosts.isNotEmpty) hosts,
    ];
    return parts.join(', ');
  }

  // Events
  static const String eventsEmpty = 'No open events right now.';
  static const String eventDeepLinkLoading = 'Opening event registration';
  static String eventDeepLinkOpening(String eventTitle) =>
      'Opening registration for $eventTitle';
  static const String eventRegistrationTitle = 'Event Registration';
  static const String eventRegistrationLoadingForm =
      'Loading registration form';
  static const String eventRegistrationRetryLoad =
      'Retry loading registration form';
  static const String submitRegistration = 'Submit Registration';
  static const String registrationPreviousPage = 'Previous';
  static const String registrationNextPage = 'Next';
  static String registrationPageLabel(int current, int total) =>
      'Page $current of $total';
  static const String registrationSuccessPrefix =
      'Registration submitted successfully. Reference: entry';
  static const String unsupportedFieldsNotice =
      'Some fields on this form are not supported in the app yet. '
      'Contact Radio Udaan if you need help completing them.';
  static const String chooseFile = 'Choose file';
  static const String registrationFieldRequired = 'This field is required.';
  static const String registrationAccountLockedHint =
      'From your account, cannot edit.';
  static const String registrationPickerDateHint =
      'Double tap to choose date';
  static const String registrationPickerTimeHint =
      'Double tap to choose time';
  static const String registrationPickerDateTimeHint =
      'Double tap to choose date and time';
  static const String registrationAddressHint =
      'Street, city, state, postal code';
  static const String registrationNoFileSelected = 'No file selected';
  static String registrationUnsupportedFieldsSemantics({
    required String notice,
    required String fieldNames,
  }) =>
      '$notice Unsupported fields: $fieldNames';
  static String registrationMultiSelectSemanticsValue(List<String> selected) =>
      selected.isEmpty ? 'None selected' : 'Selected: ${selected.join(', ')}';
  static String registrationChooseFileSemantics(
    String fieldLabel, {
    required bool required,
  }) =>
      'Choose file for $fieldLabel${required ? ', required' : ''}';
  static String registrationChangeFileSemantics(
    String fieldLabel,
    String fileName, {
    required bool required,
  }) =>
      'Change file for $fieldLabel${required ? ', required' : ''}, $fileName';
  static String registrationUploadProgressLabel(
    String fieldLabel,
    int percent,
  ) =>
      'Uploading file for $fieldLabel, $percent percent complete';
  static String registrationUploadRetryLabel(String fieldLabel) =>
      'Retry upload for $fieldLabel';

  // Library (YouTube)
  static const String librarySearchVideos = 'Search Videos';
  static const String librarySearchHint = 'Type keywords...';
  static const String libraryDurationPrefix = 'Duration: ';
  static const String librarySearchEmpty = 'No videos match your search.';
  static const String libraryPlaylists = 'Playlists';
  static const String libraryViewAllPlaylists = 'View all playlists';
  static const String libraryPlaylistsEmpty = 'No playlists available yet.';
  static const String libraryPlaylistVideosEmpty =
      'This playlist has no videos yet.';
  static const String libraryRecentUploads = 'Recent Uploads';
  static const String libraryRecentUploadsEmpty = 'No recent uploads yet.';
  static const String libraryYoutubeNotConfigured =
      'Video library is not set up on the server yet. Radio Udaan staff need to add a YouTube API key in WordPress admin.';
  static const String librarySaveVideo = 'Save';
  static const String librarySavedVideo = 'Saved';
  static const String libraryVideoSaved = 'Video saved';
  static const String libraryVideoUnsaved = 'Video removed from saved';
  static const String libraryPlayerPaused = 'Video paused';
  static const String libraryPlayerBuffering = 'Video buffering';
  static const String libraryPlayVideo = 'Play video';
  static const String libraryPauseVideo = 'Pause video';
  static const String libraryTapToPlay = 'Tap to play';
  static const String libraryPlayerNativeHint =
      'Use the play and pause buttons below to control the video.';
  static const String libraryYoutubeAttribution = 'Video hosted on YouTube';
  static const String libraryNoDescription =
      'No description available for this video.';
  static const String libraryNoVideo =
      'This video cannot be played in the app right now.';
  static const String libraryEmbedError =
      'This video could not play inside the app. Try opening it in YouTube.';
  static const String libraryOpenInYoutube = 'Open in YouTube';
  static const String libraryUploadedJustNow = 'Just now';
  static const String libraryUploadedMinuteAgo = '1 minute ago';
  static String libraryUploadedMinutesAgo(int minutes) => '$minutes minutes ago';
  static const String libraryUploadedHourAgo = '1 hour ago';
  static String libraryUploadedHoursAgo(int hours) => '$hours hours ago';
  static const String libraryUploadedYesterday = 'Yesterday';
  static String libraryUploadedDaysAgo(int days) => '$days days ago';
  static const String libraryUploadedWeekAgo = '1 week ago';
  static String libraryUploadedWeeksAgo(int weeks) => '$weeks weeks ago';
  static const String libraryUploadedMonthAgo = '1 month ago';
  static String libraryUploadedMonthsAgo(int months) => '$months months ago';
  static const String libraryUploadedYearAgo = '1 year ago';
  static String libraryUploadedYearsAgo(int years) => '$years years ago';
  static String libraryVideoSemantics({
    required String title,
    String? duration,
    String? uploaded,
    bool saved = false,
  }) {
    final parts = <String>[
      title,
      if (duration != null && duration.isNotEmpty) duration,
      if (uploaded != null && uploaded.isNotEmpty) uploaded,
      if (saved) librarySavedVideo else librarySaveVideo,
      libraryPlayVideo,
    ];
    return parts.join(', ');
  }

  // More
  static const String moreOptionsTitle = 'More Options';
  static const String moreOptionsIntro = '';
  static const String userProfile = 'User Profile';
  static const String userProfileSubtitle = 'Update your information';
  static const String aboutUs = 'About Us';
  static const String aboutUsSubtitle = 'Our story and vision';
  static const String helpAndContact = 'Contact';
  static const String helpAndContactSubtitle = 'Send a message to our team';
  static const String contactTitle = 'Contact';
  static const String contactFormTitle = 'Send us a message';
  static const String contactFormIntro =
      'Tell us what you need and our team will get back to you.';
  static const String settingsTitle = 'Settings';
  static const String settingsSubtitle = 'Accessibility and notifications';
  static const String notificationsTitle = 'Notifications';
  static const String notificationsSubtitle = 'Alerts and updates';
  static const String logout = 'Logout';
  static const String logoutSubtitle = 'Securely sign out';
  static const String madeWithAccessibility = 'Made with accessibility in mind';
  static String appVersionLabel(String version) =>
      'Radio Udaan Version $version';
  static const String legalSection = 'Legal & account';
  static const String privacyPolicy = 'Privacy policy';
  static const String termsOfUse = 'Terms of use';

  static const String editProfileTitle = 'Edit Profile';
  static const String tapToUpdatePhoto = 'Tap to update photo';
  static const String updateProfile = 'Update Profile';
  static const String profileUpdated = 'Profile updated successfully';
  static const String changePasswordTitle = 'Change Password';
  static const String changePasswordIntro =
      'Keep your account secure with a strong password.';
  static const String currentPassword = 'Current Password';
  static const String newPassword = 'New Password';
  static const String confirmNewPassword = 'Confirm New Password';
  static const String saveNewPassword = 'Save New Password';
  static const String passwordChangedSignInAgain =
      'Password changed. Please sign in again.';
  static const String passwordRequirementsNotMet =
      'Please meet all password requirements.';
  static const String profileInfoNote =
      'Your mobile number is fixed to your login. If you change your email, we send a verification code to the new address.';
  static const String profileMobileLockedHint =
      'Linked to your login. Cannot be changed here.';
  static const String profileEmailLockedHint =
      'Linked to your account. Cannot be changed here.';
  static String profileEmailSemantics(String email) =>
      'Email $email. Cannot be changed.';
  static String passwordRequirementMet(String requirement) =>
      '$requirement, met';
  static String passwordRequirementNotMet(String requirement) =>
      '$requirement, not met';
  static const String profileEmailVerificationSent =
      'Verification code sent to your new email. Enter the code on the next screen.';
  static String profileMobileSemantics(String phone) =>
      'Mobile number $phone. Cannot be changed.';

  static const String settingsIntro =
      'Customize your accessibility and notification preferences.';
  static const String accessibilitySection = 'Accessibility';
  static const String highContrastMode = 'High Contrast Mode';
  static const String highContrastModeHint =
      'Maximize visibility of interface elements';
  static const String textSize = 'Text Size';
  static const String textSizeSlower = 'Smaller';
  static const String textSizeNormal = 'Normal';
  static const String textSizeFaster = 'Larger';
  static const String textSizeSliderHint =
      'Drag to adjust text size from smaller to larger';
  static const String boldText = 'Bold Text';
  static const String boldTextHint = 'Heavier text for easier reading';
  static const String reduceMotion = 'Reduce Motion';
  static const String reduceMotionHint = 'Limit animations in the app';
  static const String notificationsSection = 'Notifications';
  static const String notifyLiveBroadcasts = 'Live Broadcasts';
  static const String notifyEventAlerts = 'Event Alerts';
  static const String notifyPromotions = 'Promotions';
  static const String savePreferences = 'Save Preferences';
  static const String preferencesSaved = 'Preferences saved';
  static const String preferencesSaveFailed =
      'Could not save preferences. Try again.';
  static const String preferencesDiscarded =
      'Unsaved preference changes discarded';
  static String unreadNotificationsBadge(int count) =>
      count == 1 ? '1 unread notification' : '$count unread notifications';

  static const String helpTitle = 'How can we help?';
  static const String helpSearchHint = 'Search FAQ or Support Topics';
  static const String sendUsAMessage = 'Send us a message';
  static const String helpSubject = 'Subject';
  static const String helpMessage = 'Message';
  static const String sendMessage = 'Send Message';
  static const String messageSent = 'Message sent. Our team will reply soon.';
  static const String stillNeedHelp = 'Still need help?';
  static const String emailSupport = 'Email Support';
  static const String callAccessibilityHelpline = 'Call Accessibility Helpline';
  static const String joinCommunity = 'Join Community';
  static const List<String> helpFaqTopics = [
    'How do I register for an event?',
    'How do I listen to live radio?',
    'How do I verify my email?',
    'How do I change my password?',
    'How do I delete my account?',
  ];

  static const String notificationsFilterAll = 'All';
  static const String notificationsFilterUnread = 'Unread';
  static const String notificationsEmpty = 'No notifications yet.';
  static const String notificationsUnreadEmpty = 'No unread notifications.';
  static const String notificationsLoading = 'Loading notifications';
  static const String notificationRead = 'Read';
  static const String notificationUnread = 'Unread';

  static const String profile = 'Profile';
  static const String notSignedIn = 'Not signed in';
  static const String deleteAccount = 'Delete account';
  static const String deleteAccountSubtitle =
      'Removes your app login on our servers. Event registrations are not deleted.';
  static const String deleteAccountConfirmTitle = 'Delete account?';
  static const String deleteAccountConfirmBody =
      'This permanently deletes your app login and signs you out. '
      'You can sign in again with your phone number.\n\n'
      'Event registrations you already submitted are not removed.';
  static const String cancel = 'Cancel';
  static const String signOut = 'Sign out';
  static const String signingOut = 'Signing out';
  static const String accountDeletedSigningOut = 'Account deleted. Signing out';
  static const String emailNotVerified = 'Email not verified';
  static const String linkOpensInBrowser = 'Opens in browser';
  static const String linkUnavailable = 'This link is not available';
  static const String linkOpenFailed = 'Could not open link';
  static const String accountDeleteFailed = 'Could not delete account';

  // Debug-only labels (still defined here for consistency)
  static const String debugApiServer = 'API server';
  static const String debugApiVersion = 'App API version';
}
