// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:profit_from_it_investors/model/profile_response.dart';
import 'package:profit_from_it_investors/provider/authentication/profile_provider.dart';
import 'package:profit_from_it_investors/ui/transaction_screen/transaction_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _personalExpanded = true;
  bool _kycExpanded = false;
  bool _bankExpanded = true;
  bool _nomineeExpanded = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().getProfile(context);
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColor.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColor.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ProfileProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.danger,
              minimumSize: const Size(90, 40),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profileResponse?.data;

    final userName = _safe(profile?.name);
    final email = _safe(profile?.email);
    final clientId = _safe(profile?.code);
    final firstLetter = userName != '-' && userName.isNotEmpty
        ? userName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
      ),
      body: profileProvider.loginLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await profileProvider.getProfile(context);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                child: Column(
                  children: [
                    _buildIdentityCard(
                      profile: profile,
                      userName: userName,
                      email: email,
                      clientId: clientId,
                      firstLetter: firstLetter,
                    ),

                    const SizedBox(height: 14),

                    // Intentionally NO standalone "KYC Status: Fully Verified"
                    // banner here, as requested.
                    _buildExpandableSection(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Details',
                      subtitle: 'DOB, personal status, address',
                      expanded: _personalExpanded,
                      onTap: () {
                        setState(() {
                          _personalExpanded = !_personalExpanded;
                        });
                      },
                      child: _buildPersonalDetails(profile),
                    ),

                    const SizedBox(height: 12),

                    _buildExpandableSection(
                      icon: Icons.verified_user_outlined,
                      title: 'KYC & Regulatory Compliance',
                      subtitle: 'PAN, CKYC, income bracket',
                      expanded: _kycExpanded,
                      onTap: () {
                        setState(() {
                          _kycExpanded = !_kycExpanded;
                        });
                      },
                      child: _buildKycDetails(profile),
                    ),

                    const SizedBox(height: 12),

                    _buildExpandableSection(
                      icon: Icons.account_balance_outlined,
                      title: 'Linked Bank Accounts',
                      subtitle:
                          '${profile?.bankAccounts?.length ?? 0} account${(profile?.bankAccounts?.length ?? 0) == 1 ? '' : 's'} linked',
                      expanded: _bankExpanded,
                      onTap: () {
                        setState(() {
                          _bankExpanded = !_bankExpanded;
                        });
                      },
                      child: _buildBankAccounts(profile),
                    ),

                    const SizedBox(height: 12),

                    _buildExpandableSection(
                      icon: Icons.people_alt_outlined,
                      title: 'Nominee Details',
                      subtitle:
                          '${profile?.nominees?.length ?? 0} nominee${(profile?.nominees?.length ?? 0) == 1 ? '' : 's'}',
                      expanded: _nomineeExpanded,
                      onTap: () {
                        setState(() {
                          _nomineeExpanded = !_nomineeExpanded;
                        });
                      },
                      child: _buildNominees(profile),
                    ),

                    const SizedBox(height: 12),

                    _buildActionCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Transactions',
                      subtitle: 'View account transaction history',
                      onTap: () {
                        nextRoute(
                          MaterialPageRoute(
                            builder: (context) => TransactionScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final versionText =
                            snapshot.connectionState == ConnectionState.done &&
                                snapshot.hasData
                            ? 'Profit From It v${snapshot.data!.version}'
                            : 'Profit From It';

                        return Column(
                          children: [
                            Text(
                              versionText,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Investor Portfolio Application',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: AppColor.textLight,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          'Log Out of Account',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.textPrimary,
                          side: const BorderSide(color: Color(0xFFD8DDE7)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIdentityCard({
    required Data? profile,
    required String userName,
    required String email,
    required String clientId,
    required String firstLetter,
  }) {
    final status = _safe(profile?.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF102351),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF315EEB), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  firstLetter,
                  style: GoogleFonts.poppins(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        if (status != '-')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8FBF4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF008A60),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Text(
                          'CLIENT CODE: ',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            clientId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ),
                        if (clientId != '-') ...[
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: clientId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Client code copied',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 14,
                          color: AppColor.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(height: 1, color: Color(0xFFE7EBF2)),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _inlineIdentityItem(
                  icon: Icons.phone_outlined,
                  value: _safe(profile?.mobile),
                ),
              ),
              Container(width: 1, height: 20, color: const Color(0xFFE1E5EC)),
              const SizedBox(width: 14),
              Expanded(
                child: _inlineIdentityItem(
                  icon: Icons.badge_outlined,
                  value: 'PAN: ${_safe(profile?.panNo)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inlineIdentityItem({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColor.textSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColor.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: const Color(0xFF0D3CCF)),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE9ECF2)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: child,
                ),
              ],
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails(Data? profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _detailBox(
                label: 'Date of Birth',
                value: _safe(profile?.dob),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailBox(label: 'Gender', value: _safe(profile?.gender)),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _detailBox(
                label: 'Marital Status',
                value: _safe(profile?.maritalStatus),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailBox(
                label: 'Occupation',
                value: _safe(profile?.occupation),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _detailBox(
          label: 'Communication Address',
          value: _safe(profile?.address),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildKycDetails(Data? profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _detailBox(
                label: 'Client Code',
                value: _safe(profile?.code),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailBox(
                label: 'PAN Number',
                value: _safe(profile?.panNo),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _detailBox(
                label: 'CKYC ID',
                value: _safe(profile?.ckycId),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailBox(
                label: 'Income Bracket',
                value: _safe(profile?.incomeBracket),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _detailBox(
          label: 'Account Status',
          value: _safe(profile?.status),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildBankAccounts(Data? profile) {
    final accounts = profile?.bankAccounts ?? [];

    if (accounts.isEmpty) {
      return _emptyState(
        icon: Icons.account_balance_outlined,
        message: 'No bank accounts available',
      );
    }

    return Column(
      children: List.generate(accounts.length, (index) {
        final bank = accounts[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == accounts.length - 1 ? 0 : 10,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8E2F7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE1E6F0)),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    size: 21,
                    color: AppColor.primary,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _safe(bank.bankName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _maskAccountNumber(bank.accountNumber),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_safe(bank.status) != '-')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9FBF3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _safe(bank.status),
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF008A60),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNominees(Data? profile) {
    final nominees = profile?.nominees ?? [];

    if (nominees.isEmpty) {
      return _emptyState(
        icon: Icons.people_alt_outlined,
        message: 'No nominee details available',
      );
    }

    return Column(
      children: List.generate(nominees.length, (index) {
        final nominee = nominees[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == nominees.length - 1 ? 0 : 10,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E7F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColor.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _safe(nominee.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _safe(nominee.relation),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_safe(nominee.share)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _detailBox({
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE5F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 8.5,
              color: AppColor.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColor.textLight, size: 24),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E7EF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColor.primary),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColor.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _maskAccountNumber(String? raw) {
    final value = (raw ?? '').trim();

    if (value.isEmpty) {
      return '-';
    }

    if (value.length <= 4) {
      return value;
    }

    return '•••• •••• ${value.substring(value.length - 4)}';
  }

  String _safe(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? '-' : text;
  }
}
