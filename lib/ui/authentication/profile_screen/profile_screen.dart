// ignore_for_file: unused_field

import 'package:flutter/material.dart';
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
  static const List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.person_outline, 'label': 'Personal Details'},
    {'icon': Icons.badge_outlined, 'label': 'KYC Details'},
    {'icon': Icons.account_balance_outlined, 'label': 'Bank Accounts'},
    {'icon': Icons.people_outline, 'label': 'Nominee Details'},
  ];

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ProfileProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.danger, minimumSize: const Size(90, 40)),
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete your account?', style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ProfileProvider>().deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.danger, minimumSize: const Size(90, 40)),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profileResponse?.data;

    final String userName = profile?.name ?? '-';
    final String email = profile?.email ?? '-';
    final String clientId = profile?.code ?? '-';

    final String firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: profileProvider.loginLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await profileProvider.getProfile(context);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(color: AppColor.primary, shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      firstLetter,
                                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(clientId, style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Card(
                            elevation: 5,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(children: [_buildPersonalDetails(profile), const Divider(height: 1), _buildKycDetails(profile), const Divider(height: 1), _buildBankAccounts(profile), const Divider(height: 1), _buildNominees(profile)]),
                          ),

                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                            ),
                            child: _MenuItem(
                              icon: Icons.payments_outlined,
                              label: 'Transactions',
                              iconColor: AppColor.primary,
                              textColor: AppColor.primary,
                              showArrow: false,
                              onTap: () {
                                nextRoute(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return TransactionScreen();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// Logout
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                            ),
                            child: _MenuItem(icon: Icons.logout, label: 'Logout', iconColor: AppColor.danger, textColor: AppColor.danger, showArrow: false, onTap: () => _showLogoutDialog(context)),
                          ),

                          const SizedBox(height: 24),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                            ),
                            child: _MenuItem(icon: Icons.delete, label: 'Delete Account', iconColor: AppColor.danger, textColor: AppColor.danger, showArrow: false, onTap: () => _showDeleteAccountDialog(context)),
                          ),

                          const SizedBox(height: 24),

                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                return Text('Version ${snapshot.data!.version} (BETA)', style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textLight));
                              } else {
                                return Text('Version: Loading...', style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textLight));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails(Data? profile) {
    return ExpansionTile(
      leading: const Icon(Icons.person_outline),
      title: Text('Personal Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      children: [_infoTile('Name', profile?.name), _infoTile('Mobile', profile?.mobile), _infoTile('Email', profile?.email), _infoTile('Gender', profile?.gender), _infoTile('DOB', profile?.dob), _infoTile('Address', profile?.address), _infoTile('Occupation', profile?.occupation)],
    );
  }

  Widget _buildKycDetails(Data? profile) {
    return ExpansionTile(
      leading: const Icon(Icons.badge_outlined),
      title: Text('KYC Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      children: [_infoTile('Client Code', profile?.code), _infoTile('PAN Number', profile?.panNo), _infoTile('CKYC ID', profile?.ckycId), _infoTile('Income Bracket', profile?.incomeBracket), _infoTile('Status', profile?.status)],
    );
  }

  Widget _buildBankAccounts(Data? profile) {
    final accounts = profile?.bankAccounts ?? [];

    return ExpansionTile(
      leading: const Icon(Icons.account_balance_outlined),
      title: Text('Bank Accounts (${accounts.length})', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      children: accounts.map((bank) {
        return ListTile(
          title: Text(bank.bankName ?? '-', style: GoogleFonts.poppins()),
          subtitle: Text(bank.accountNumber ?? '-', style: GoogleFonts.poppins(fontSize: 12)),
          trailing: Text(
            bank.status ?? '-',
            style: GoogleFonts.poppins(color: AppColor.primary, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNominees(Data? profile) {
    final nominees = profile?.nominees ?? [];

    return ExpansionTile(
      leading: const Icon(Icons.people_outline),
      title: Text('Nominee Details (${nominees.length})', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      children: nominees.map((nominee) {
        return ListTile(
          title: Text(nominee.name ?? '-', style: GoogleFonts.poppins()),
          subtitle: Text('Relation: ${nominee.relation ?? '-'}', style: GoogleFonts.poppins(fontSize: 12)),
          trailing: Text(
            '${nominee.share ?? '0'}%',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColor.primary),
          ),
        );
      }).toList(),
    );
  }

  Widget _infoTile(String title, String? value) {
    return ListTile(
      dense: true,
      title: Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
      subtitle: Text((value?.trim().isNotEmpty ?? false) ? value! : '-', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool showArrow;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.iconColor, this.textColor, this.showArrow = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColor.textSecondary, size: 22),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor ?? AppColor.textPrimary),
              ),
            ),

            if (showArrow) const Icon(Icons.chevron_right, color: AppColor.textLight, size: 22),
          ],
        ),
      ),
    );
  }
}
