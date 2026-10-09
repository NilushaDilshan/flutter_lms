import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../auth/models/user_model.dart';
import '../providers/admin_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleStatus(UserModel user) async {
    final isCurrentlyActive = user.isActive;
    final targetStatus = isCurrentlyActive ? 'SUSPENDED' : 'ACTIVE';
    final actionName = isCurrentlyActive ? 'Suspend' : 'Reactivate';

    final confirmed = await ConfirmationDialog.show(
      context,
      title: '$actionName User Account',
      message: isCurrentlyActive
          ? 'Suspending ${user.fullName} (${user.email}) will immediately revoke access and invalidate all active sessions until reactivated.'
          : 'Reactivating ${user.fullName} will restore full platform access. The user will be able to log in again.',
      confirmText: actionName,
      confirmColor: isCurrentlyActive ? AppColors.error : AppColors.success,
      icon: isCurrentlyActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
    );

    if (confirmed && mounted) {
      final provider = context.read<AdminProvider>();
      final success = await provider.updateUserStatus(user.id, targetStatus);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: isCurrentlyActive ? Colors.orange.shade800 : AppColors.success,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'User ${user.fullName} is now ${targetStatus.toLowerCase()}.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(provider.errorMessage ?? 'Failed to update user status.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final users = adminProvider.filteredUsers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Users',
            onPressed: () => adminProvider.loadUsers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              adminProvider.setUserSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) => adminProvider.setUserSearch(val),
                ),
                const SizedBox(height: 10),

                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Role:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('All Roles', 'ALL', adminProvider),
                      _buildRoleFilterChip('Student', 'STUDENT', adminProvider),
                      _buildRoleFilterChip('Instructor', 'INSTRUCTOR', adminProvider),
                      _buildRoleFilterChip('Admin', 'ADMIN', adminProvider),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('All Status', 'ALL', adminProvider),
                      _buildStatusFilterChip('Active', 'ACTIVE', adminProvider),
                      _buildStatusFilterChip('Suspended', 'SUSPENDED', adminProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User count indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Text(
              'Showing ${users.length} account${users.length == 1 ? "" : "s"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),

          // Users List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => adminProvider.loadUsers(),
              child: adminProvider.isLoading
                  ? const LoadingStateWidget(message: 'Loading platform users...')
                  : users.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: 'No Users Found',
                          message: 'No users match your current search or filter criteria.',
                          actionText: 'Reset Filters',
                          onAction: () {
                            _searchController.clear();
                            adminProvider.setUserSearch('');
                            adminProvider.setRoleFilter('ALL');
                            adminProvider.setUserStatusFilter('ALL');
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _buildUserCard(user);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.selectedRoleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setRoleFilter(value),
        selectedColor: AppColors.primary.withAlpha(30),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 11,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.selectedUserStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setUserStatusFilter(value),
        selectedColor: AppColors.adminRole.withAlpha(30),
        checkmarkColor: AppColors.adminRole,
        labelStyle: TextStyle(
          fontSize: 11,
          color: isSelected ? AppColors.adminRole : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    Color roleColor;
    IconData roleIcon;
    switch (user.role) {
      case 'ADMIN':
        roleColor = AppColors.adminRole;
        roleIcon = Icons.security_rounded;
        break;
      case 'INSTRUCTOR':
        roleColor = AppColors.instructorRole;
        roleIcon = Icons.co_present_rounded;
        break;
      default:
        roleColor = AppColors.studentRole;
        roleIcon = Icons.school_rounded;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withAlpha(25),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Animated Status Badge (Day 9 AnimatedContainer feature!)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: user.isActive ? Colors.green.shade300 : Colors.red.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isActive ? Icons.check_circle : Icons.cancel,
                              size: 11,
                              color: user.isActive ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: user.isActive ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),

                  // Role Badge & Email Verified Indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 11, color: roleColor),
                            const SizedBox(width: 4),
                            Text(
                              user.role,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user.isEmailVerified)
                        const Row(
                          children: [
                            Icon(Icons.verified, size: 12, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text('Verified', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Suspend / Reactivate Action Menu
            if (!user.isAdmin)
              IconButton(
                icon: Icon(
                  user.isActive ? Icons.block_rounded : Icons.replay_rounded,
                  color: user.isActive ? Colors.orange.shade800 : AppColors.success,
                  size: 22,
                ),
                tooltip: user.isActive ? 'Suspend User' : 'Reactivate User',
                onPressed: () => _handleToggleStatus(user),
              ),
          ],
        ),
      ),
    );
  }
}
