import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';
import '../../../core/database/app_database.dart';
import '../../../core/theme/villahermosa_theme.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';

/// User Accounts & Permissions screen
/// Manages user access, roles, and security settings
class UserAccountsScreen extends StatefulWidget {
  const UserAccountsScreen({
    super.key,
    required this.database,
    required this.syncManager,
  });

  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<UserAccountsScreen> createState() => _UserAccountsScreenState();
}

class _UserAccountsScreenState extends State<UserAccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<User>> _usersStream;
  List<User> _allUsers = []; // Store all users from stream
  List<User> _filteredUsers = [];
  StreamSubscription<List<User>>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _setupUserStream();
    _pullUsersInBackground();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupUserStream() {
    _usersStream = widget.database.getAllUsersStream();
    
    // Set up stream listener to update local state
    _userSubscription = _usersStream.listen((users) {
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = _applySearchFilter(users, _searchController.text);
        });
      }
    });
  }

  Future<void> _pullUsersInBackground() async {
    try {
      await widget.syncManager.pull();
    } catch (e) {
      debugPrint('Background pull failed: $e');
    }
  }

  String _getDisplayName(User user) {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    if (first.length > 1 || last.length > 1) {
      return '$first $last'.trim();
    }
    // Fall back to email prefix if name looks wrong
    return user.email.split('@').first;
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredUsers = _applySearchFilter(_allUsers, _searchController.text);
    });
  }

  List<User> _applySearchFilter(List<User> users, String query) {
    if (query.isEmpty) {
      return users;
    } else {
      final lowerQuery = query.toLowerCase();
      return users.where((user) {
        final fullName = _getDisplayName(user).toLowerCase();
        final email = user.email.toLowerCase();
        return fullName.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    }
  }

  Future<void> _loadUsers() async {
    // This method is no longer needed - using streams instead
  }

  String _getPermissionsForRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Full Access';
      case 'warehouse':
        return 'Inventory';
      case 'sales_rep':
        return 'Orders, Customers';
      case 'delivery':
        return 'Delivery';
      default:
        return 'Limited';
    }
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VillahermosaColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VillahermosaColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: VillahermosaColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            value,
            style: VillahermosaTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: VillahermosaTextStyles.small,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTable() {
    return Container(
      decoration: BoxDecoration(
        color: VillahermosaColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VillahermosaColors.borderColor),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: VillahermosaColors.contentBg,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'NAME',
                    style: VillahermosaTextStyles.extraSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'EMAIL',
                    style: VillahermosaTextStyles.extraSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'ROLE',
                    style: VillahermosaTextStyles.extraSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PERMISSIONS',
                    style: VillahermosaTextStyles.extraSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'STATUS',
                    style: VillahermosaTextStyles.extraSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'LAST LOGIN',
                    style: VillahermosaTextStyles.extraSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 80), // Actions column
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _filteredUsers.map((user) => _buildUserRow(user)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: VillahermosaColors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        child: Row(
          children: [
            // Name
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: VillahermosaColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDisplayName(user),
                      style: VillahermosaTextStyles.small,
                    ),
                  ),
                ],
              ),
            ),
            // Email
            Expanded(
              flex: 2,
              child: Text(
                user.email,
                style: VillahermosaTextStyles.small,
              ),
            ),
            // Role
            Expanded(
              flex: 1,
              child: Text(
                user.role,
                style: VillahermosaTextStyles.small,
              ),
            ),
            // Permissions
            Expanded(
              flex: 2,
              child: Text(
                _getPermissionsForRole(user.role),
                style: VillahermosaTextStyles.small,
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: _buildStatusBadge(user.isActive),
            ),
            // Last Login
            Expanded(
              flex: 2,
              child: Text(
                _formatDateTime(user.updatedAt),
                style: VillahermosaTextStyles.small,
              ),
            ),
            // Actions
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _editUser(user),
                    tooltip: 'Edit User',
                  ),
                  IconButton(
                    icon: const Icon(Icons.key_outlined, size: 18),
                    onPressed: () => _resetPassword(user),
                    tooltip: 'Reset Password',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? VillahermosaColors.successBg : VillahermosaColors.errorBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: VillahermosaTextStyles.extraSmall.copyWith(
          color: isActive ? VillahermosaColors.successText : VillahermosaColors.errorText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(
        database: widget.database,
        onUserAdded: _loadUsers,
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(user: user),
    );
  }

  void _editUser(User user) {
    showDialog(
      context: context,
      builder: (context) => _EditUserDialog(
        database: widget.database,
        user: user,
        onUserUpdated: () {
          // Stream will automatically refresh the UI
        },
      ),
    );
  }

  void _resetPassword(User user) {
    showDialog(
      context: context,
      builder: (context) => _ResetPasswordDialog(
        database: widget.database,
        user: user,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/users',
      child: Scaffold(
        backgroundColor: VillahermosaColors.contentBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Accounts & Permissions',
                          style: VillahermosaTextStyles.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage user access and security.',
                          style: VillahermosaTextStyles.small,
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _showAddUserDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VillahermosaColors.textPrimary,
                        foregroundColor: VillahermosaColors.cardBg,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('+ Add User'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search_outlined),
                    filled: true,
                    fillColor: VillahermosaColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: VillahermosaColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: VillahermosaColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: VillahermosaColors.textPrimary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'Total Users',
                        value: _allUsers.length.toString(),
                        icon: Icons.people_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Active Users',
                        value: _allUsers.where((u) => u.isActive).length.toString(),
                        icon: Icons.verified_user_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Administrators',
                        value: _allUsers.where((u) => u.role == 'admin').length.toString(),
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Sales Reps',
                        value: _allUsers.where((u) => u.role == 'sales_rep').length.toString(),
                        icon: Icons.person_pin_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // User Table
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildUserTable(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({
    required this.database,
    required this.onUserAdded,
  });

  final AppDatabase database;
  final VoidCallback onUserAdded;

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'sales_rep';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VillahermosaColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New User',
              style: VillahermosaTextStyles.h3,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: _buildInputDecoration('First Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: _buildInputDecoration('Last Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: _buildInputDecoration('Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: _buildInputDecoration('Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: _buildInputDecoration('Role'),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                      DropdownMenuItem(value: 'warehouse', child: Text('Warehouse Manager')),
                      DropdownMenuItem(value: 'sales_rep', child: Text('Sales Representative')),
                      DropdownMenuItem(value: 'delivery', child: Text('Delivery Driver')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VillahermosaColors.textPrimary,
                    foregroundColor: VillahermosaColors.cardBg,
                  ),
                  child: const Text('Add User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: VillahermosaColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.textPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = UsersCompanion.insert(
          uuid: const Uuid().v4(),
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          passwordHash: _hashPassword(_passwordController.text),
          role: _selectedRole,
          isActive: const drift.Value(true),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('pending'),
          createdAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
        );

        await widget.database.createUser(user);
        if (mounted) {
          widget.onUserAdded();
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding user: $e')),
          );
        }
      }
    }
  }

  /// Hash password using SHA-256 algorithm
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class _UserDetailsDialog extends StatelessWidget {
  final User user;

  const _UserDetailsDialog({required this.user});

  String _getDisplayName(User user) {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    if (first.length > 1 || last.length > 1) {
      return '$first $last'.trim();
    }
    // Fall back to email prefix if name looks wrong
    return user.email.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VillahermosaColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Details',
                  style: VillahermosaTextStyles.h3,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Name', _getDisplayName(user)),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Role', user.role),
            _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Last Login', 
                '${user.updatedAt.day}/${user.updatedAt.month}/${user.updatedAt.year}'),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: VillahermosaTextStyles.small.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: VillahermosaTextStyles.small,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  const _EditUserDialog({
    required this.database,
    required this.user,
    required this.onUserUpdated,
  });

  final AppDatabase database;
  final User user;
  final VoidCallback onUserUpdated;

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VillahermosaColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit User',
              style: VillahermosaTextStyles.h3,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: _buildInputDecoration('First Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: _buildInputDecoration('Last Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: _buildInputDecoration('Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: _buildInputDecoration('Role'),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                      DropdownMenuItem(value: 'warehouse', child: Text('Warehouse Manager')),
                      DropdownMenuItem(value: 'sales_rep', child: Text('Sales Representative')),
                      DropdownMenuItem(value: 'delivery', child: Text('Delivery Driver')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VillahermosaColors.textPrimary,
                    foregroundColor: VillahermosaColors.cardBg,
                  ),
                  child: const Text('Update User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: VillahermosaColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.textPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedUser = UsersCompanion(
          firstName: drift.Value(_firstNameController.text),
          lastName: drift.Value(_lastNameController.text),
          email: drift.Value(_emailController.text),
          role: drift.Value(_selectedRole),
          syncStatus: const drift.Value('pending'),
          updatedAt: drift.Value(DateTime.now()),
        );

        await widget.database.updateUser(widget.user.uuid, updatedUser);
        if (mounted) {
          widget.onUserUpdated();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating user: $e')),
          );
        }
      }
    }
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final User user;
  final AppDatabase database;

  const _ResetPasswordDialog({required this.user, required this.database});

  String _getDisplayName(User user) {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    if (first.length > 1 || last.length > 1) {
      return '$first $last'.trim();
    }
    // Fall back to email prefix if name looks wrong
    return user.email.split('@').first;
  }

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VillahermosaColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Password for ${widget._getDisplayName(widget.user)}',
              style: VillahermosaTextStyles.h3,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _passwordController,
                decoration: _buildInputDecoration('New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VillahermosaColors.textPrimary,
                    foregroundColor: VillahermosaColors.cardBg,
                  ),
                  child: const Text('Reset Password'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: VillahermosaColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: VillahermosaColors.textPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedUser = UsersCompanion(
          passwordHash: drift.Value(_hashPassword(_passwordController.text)),
          forcePasswordChange: const drift.Value(true),
          syncStatus: const drift.Value('pending'),
          updatedAt: drift.Value(DateTime.now()),
        );

        await widget.database.updateUser(widget.user.uuid, updatedUser);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully! User must change password on next login.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting password: $e')),
          );
        }
      }
    }
  }

  /// Hash password using SHA-256 algorithm
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
