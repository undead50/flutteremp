/// Palette role an icon is tinted with in dark mode.
enum IconTone {
  onSurface,
  onSurfaceVariant,
  outline,
  brand,
  brandMuted,
  onMint,
  secondary,
  error,
  escalationText,
}

/// Typed paths for every asset exported from Figma. Screens reference these
/// constants only; there are no path strings scattered through the widgets.
abstract final class AppIcons {
  static const String _dir = 'assets/icons';

  /// Most exported glyphs have one dark colour baked in (ink on a light
  /// surface), which would vanish on a dark background. In dark mode these are
  /// tinted with the role that matches their baked colour and surface; light
  /// mode keeps the exported colours untouched. Multi-colour marks (Google,
  /// logo, Face ID), white-on-fill glyphs and glyphs on fixed-colour fills
  /// (amber, orange) are intentionally absent.
  static const Map<String, IconTone> darkTones = <String, IconTone>{
    feedArchive: IconTone.brand,
    feedTabMemos: IconTone.brand,
    welcomeArrowRight: IconTone.brand,
    welcomeClock: IconTone.brand,
    welcomeFingerprint: IconTone.brand,
    loginShieldCheck: IconTone.onMint,
    feedVerified: IconTone.onMint,
    welcomeDocument: IconTone.onMint,
    detailBack: IconTone.onSurface,
    detailRevision: IconTone.onSurface,
    feedReview: IconTone.onSurface,
    welcomeBuilding: IconTone.onSurface,
    detailLock: IconTone.brandMuted,
    detailVerifiedUser: IconTone.brandMuted,
    detailClock: IconTone.onSurfaceVariant,
    feedArrowRight: IconTone.onSurfaceVariant,
    feedAttachBudget: IconTone.onSurfaceVariant,
    feedAttachDocument: IconTone.onSurfaceVariant,
    feedAttachSchedule: IconTone.onSurfaceVariant,
    feedTabBudgets: IconTone.onSurfaceVariant,
    feedTabLeave: IconTone.onSurfaceVariant,
    feedTabPolicies: IconTone.onSurfaceVariant,
    feedTeams: IconTone.onSurfaceVariant,
    headerSearch: IconTone.onSurfaceVariant,
    loginHeadset: IconTone.onSurfaceVariant,
    navActivity: IconTone.onSurfaceVariant,
    navModules: IconTone.onSurfaceVariant,
    navSettings: IconTone.onSurfaceVariant,
    feedPriority: IconTone.escalationText,
    detailStepNext: IconTone.outline,
    loginEye: IconTone.outline,
    loginLock: IconTone.outline,
    loginMail: IconTone.outline,
    welcomeShield: IconTone.secondary,
    detailDecline: IconTone.error,
  };

  // Welcome
  static const String welcomeDocument = '$_dir/welcome_document.svg';
  static const String welcomeArrowRight = '$_dir/welcome_arrow_right.svg';
  static const String welcomeClock = '$_dir/welcome_clock.svg';
  static const String welcomeShield = '$_dir/welcome_shield.svg';
  static const String welcomeWorkId = '$_dir/welcome_work_id.svg';
  static const String welcomeBuilding = '$_dir/welcome_building.svg';
  static const String welcomeFingerprint = '$_dir/welcome_fingerprint.svg';

  // Sign in
  static const String logoMark = '$_dir/logo_mark.svg';
  static const String loginGoogle = '$_dir/login_google.svg';
  static const String loginMail = '$_dir/login_mail.svg';
  static const String loginLock = '$_dir/login_lock.svg';
  static const String loginEye = '$_dir/login_eye.svg';
  static const String loginArrowRight = '$_dir/login_arrow_right.svg';
  static const String loginFaceId = '$_dir/login_face_id.svg';
  static const String loginShieldCheck = '$_dir/login_shield_check.svg';
  static const String loginHeadset = '$_dir/login_headset.svg';

  // Memo feed
  static const String feedTabMemos = '$_dir/feed_tab_memos.svg';
  static const String feedTabBudgets = '$_dir/feed_tab_budgets.svg';
  static const String feedTabLeave = '$_dir/feed_tab_leave.svg';
  static const String feedTabPolicies = '$_dir/feed_tab_policies.svg';
  static const String feedPriority = '$_dir/feed_priority.svg';
  static const String feedAttachBudget = '$_dir/feed_attach_budget.svg';
  static const String feedAttachDocument = '$_dir/feed_attach_document.svg';
  static const String feedAttachSchedule = '$_dir/feed_attach_schedule.svg';
  static const String feedVerified = '$_dir/feed_verified.svg';
  static const String feedTeams = '$_dir/feed_teams.svg';
  static const String feedEstimate = '$_dir/feed_estimate.svg';
  static const String feedApprove = '$_dir/feed_approve.svg';
  static const String feedReview = '$_dir/feed_review.svg';
  static const String feedArchive = '$_dir/feed_archive.svg';
  static const String feedArrowRight = '$_dir/feed_arrow_right.svg';

  // Shell
  static const String headerSearch = '$_dir/header_search.svg';
  static const String navMemos = '$_dir/nav_memos.svg';
  static const String navModules = '$_dir/nav_modules.svg';
  static const String navActivity = '$_dir/nav_activity.svg';
  static const String navSettings = '$_dir/nav_settings.svg';

  // Memo detail
  static const String detailBack = '$_dir/detail_back.svg';
  static const String detailClock = '$_dir/detail_clock.svg';
  static const String detailStepDone = '$_dir/detail_step_done.svg';
  static const String detailStepPending = '$_dir/detail_step_pending.svg';
  static const String detailStepNext = '$_dir/detail_step_next.svg';
  static const String detailVerifiedUser = '$_dir/detail_verified_user.svg';
  static const String detailLock = '$_dir/detail_lock.svg';
  static const String detailApprove = '$_dir/detail_approve.svg';
  static const String detailRevision = '$_dir/detail_revision.svg';
  static const String detailDecline = '$_dir/detail_decline.svg';
}

abstract final class AppImages {
  static const String _dir = 'assets/images';

  static const String relayEmblem = '$_dir/relay_emblem.png';
  static const String appEmblem = '$_dir/app_emblem.png';
  static const String appEmblemDetail = '$_dir/app_emblem_detail.png';

  static const String avatarElena = '$_dir/avatar_elena_vance.png';
  static const String avatarMaya = '$_dir/avatar_maya_lin.png';
  static const String avatarJulian = '$_dir/avatar_julian_sorel.png';
  static const String avatarKareena = '$_dir/avatar_kareena_patel.png';
  static const String avatarMarcus = '$_dir/avatar_marcus_vance.png';
  static const String avatarTeam1 = '$_dir/avatar_team_1.png';
  static const String avatarTeam2 = '$_dir/avatar_team_2.png';

  /// Scheme used by mock data sources to reference bundled avatars. Remote
  /// payloads may only supply https URLs; see `AvatarSource`.
  static const String assetScheme = 'asset:';
}
