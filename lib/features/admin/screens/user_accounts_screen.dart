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
import '../widgets/mobile_list_card.dart';

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
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  StreamSubscription<List<User>>? _userSubscription;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _userSubscription = widget.database.getAllUsersStream().listen((users) {
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = _applyFilters(users);
        });
      }
    });
    _searchController.addListener(_onSearchChanged);
    _pullUsersInBackground();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pullUsersInBackground() async {
    try {
      await widget.syncManager.pull();
    } catch (e) {
      debugPrint('Background pull failed: $e');
    }
  }

  void _onSearchChanged() {
    setState(() => _filteredUsers = _applyFilters(_allUsers));
  }

  void _selectTab(String tab) {
    setState(() {
      _selectedTab = tab;
      _filteredUsers = _applyFilters(_allUsers);
    });
  }

  List<User> _applyFilters(List<User> users) {
    var result = users;
    switch (_selectedTab) {
      case 'admin':
        result = result.where((u) => u.role == 'admin').toList();
      case 'sales_rep':
        result = result.where((u) => u.role == 'sales_rep').toList();
      case 'warehouse':
        result = result.where((u) => u.role == 'warehouse').toList();
      case 'inactive':
        result = result.where((u) => !u.isActive).toList();
    }
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((u) =>
        _getDisplayName(u).toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q),
      ).toList();
    }
    return result;
  }

  String _getDisplayName(User user) {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    if (first.length > 1 || last.length > 1) return '$first $last'.trim();
    return user.email.split('@').first;
  }

  String _getInitials(User user) {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    return user.email[0].toUpperCase();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(
        database: widget.database,
        onUserAdded: () {},
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
        onUserUpdated: () {},
      ),
    );
  }

  Future<void> _deactivateUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Deactivate ${_getDisplayName(user)}? They will no longer be able to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await widget.database.deactivateUser(user.uuid);
    }
  }

  // ─── STAT CARD ──────────────────────────────────

  Widget _statCard({
    required String label,
    required String value,
    required Color dotColor,
    required String sub,
  }) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 3),
          Row(children: [
            Container(width: 6, height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Expanded(child: Text(sub,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );

  // ─── ROLE BADGE ─────────────────────────────────

  Widget _roleBadge(String role) {
    Color bg, fg;
    String label;
    switch (role) {
      case 'admin':
        bg = const Color(0xFFEFF6FF); fg = const Color(0xFF1E40AF); label = 'Admin';
      case 'sales_rep':
        bg = const Color(0xFFF0FDF4); fg = const Color(0xFF166534); label = 'Sales Rep';
      case 'warehouse':
        bg = const Color(0xFFFFFBEB); fg = const Color(0xFF92400E); label = 'Warehouse';
      case 'delivery':
        bg = const Color(0xFFF5F3FF); fg = const Color(0xFF5B21B6); label = 'Delivery';
      default:
        bg = const Color(0xFFF3F4F6); fg = const Color(0xFF374151); label = role;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  // ─── STATUS BADGE ───────────────────────────────

  Widget _statusBadge(bool isActive) {
    final bg = isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final fg = isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(isActive ? 'Active' : 'Inactive',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  // ─── TAB BAR ────────────────────────────────────

  Widget _buildTabs() {
    final tabs = [
      ('all', 'All Users', _allUsers.length),
      ('admin', 'Admins', _allUsers.where((u) => u.role == 'admin').length),
      ('sales_rep', 'Sales Reps', _allUsers.where((u) => u.role == 'sales_rep').length),
      ('warehouse', 'Warehouse', _allUsers.where((u) => u.role == 'warehouse').length),
      ('inactive', 'Inactive', _allUsers.where((u) => !u.isActive).length),
    ];
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final (key, label, count) = t;
            final selected = _selectedTab == key;
            return GestureDetector(
              onTap: () => _selectTab(key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? const Color(0xFF111827) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(children: [
                  Text('$label ($count)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? const Color(0xFF111827) : const Color(0xFF6B7280),
                    )),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── TOOLBAR ────────────────────────────────────

  Widget _buildToolbar() {
    final searchField = SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_outlined, size: 16, color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5),
          ),
        ),
      ),
    );
    final filterButton = OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.filter_list_outlined, size: 14),
      label: const Text('Filter', style: TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
    final addButton = ElevatedButton.icon(
      onPressed: _showAddUserDialog,
      icon: const Icon(Icons.add, size: 14, color: Colors.white),
      label: const Text('Add User', style: TextStyle(fontSize: 13, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 500) {
        return Column(children: [
          searchField,
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: filterButton),
            const SizedBox(width: 8),
            Expanded(child: addButton),
          ]),
        ]);
      }
      return Row(children: [
        Expanded(child: searchField),
        const SizedBox(width: 8),
        filterButton,
        const SizedBox(width: 8),
        addButton,
      ]);
    });
  }

  // ─── TABLE ──────────────────────────────────────

  static const _colHeader = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280),
    letterSpacing: 0.5,
  );

  Widget _buildTableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    color: const Color(0xFFF9FAFB),
    child: const Row(children: [
      Expanded(flex: 3, child: Text('NAME', style: _colHeader)),
      Expanded(flex: 3, child: Text('EMAIL', style: _colHeader)),
      Expanded(flex: 2, child: Text('ROLE', style: _colHeader)),
      Expanded(flex: 2, child: Text('STATUS', style: _colHeader)),
      Expanded(flex: 2, child: Text('CREATED', style: _colHeader)),
      SizedBox(width: 96, child: Text('ACTIONS', style: _colHeader)),
    ]),
  );

  Widget _buildUserRow(User user, bool isLast) {
    final name = _getDisplayName(user);
    final initials = _getInitials(user);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(children: [
        // NAME — avatar + full name
        Expanded(
          flex: 3,
          child: Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF1E1E1E),
              child: Text(initials,
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
        // EMAIL
        Expanded(
          flex: 3,
          child: Text(user.email,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            overflow: TextOverflow.ellipsis),
        ),
        // ROLE badge
        Expanded(flex: 2, child: _roleBadge(user.role)),
        // STATUS badge
        Expanded(flex: 2, child: _statusBadge(user.isActive)),
        // CREATED date
        Expanded(
          flex: 2,
          child: Text(_formatDate(user.createdAt),
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ),
        // ACTIONS
        SizedBox(
          width: 96,
          child: Row(children: [
            _actionBtn(Icons.visibility_outlined, 'View', () => _showUserDetails(user)),
            _actionBtn(Icons.edit_outlined, 'Edit', () => _editUser(user)),
            _actionBtn(Icons.person_off_outlined, 'Deactivate', () => _deactivateUser(user),
              color: const Color(0xFFDC2626)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildUserMobileCard(User user) {
    final name = _getDisplayName(user);
    final initials = _getInitials(user);
    return MobileListCard(
      onTap: () => _showUserDetails(user),
      primary: Row(children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF1E1E1E),
          child: Text(initials,
              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
      badge: _roleBadge(user.role),
      secondary: MobileCardMuted(user.email),
      valueLeft: _statusBadge(user.isActive),
      valueRight: MobileCardMuted(_formatDate(user.createdAt)),
      actions: [
        MobileCardAction(label: 'Edit', onPressed: () => _editUser(user)),
        MobileCardAction(
          label: 'Deactivate',
          color: const Color(0xFFDC2626),
          onPressed: () => _deactivateUser(user),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String tip, VoidCallback onTap, {Color? color}) =>
    Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color ?? const Color(0xFF6B7280)),
        ),
      ),
    );

  // ─── BUILD ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalUsers = _allUsers.length;
    final activeUsers = _allUsers.where((u) => u.isActive).length;
    final adminCount = _allUsers.where((u) => u.role == 'admin').length;
    final salesCount = _allUsers.where((u) => u.role == 'sales_rep').length;

    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/users',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                const Text('User Accounts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                const Text('Manage user access and security settings.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                const SizedBox(height: 20),

                // ── Stat Cards ──
                LayoutBuilder(builder: (context, constraints) {
                  final cards = [
                    _statCard(label: 'Total Users', value: totalUsers.toString(),
                        dotColor: const Color(0xFF6B7280), sub: 'registered accounts'),
                    _statCard(label: 'Active Users', value: activeUsers.toString(),
                        dotColor: const Color(0xFF10B981), sub: 'currently active'),
                    _statCard(label: 'Administrators', value: adminCount.toString(),
                        dotColor: const Color(0xFF3B82F6), sub: 'full admin access'),
                    _statCard(label: 'Sales Reps', value: salesCount.toString(),
                        dotColor: const Color(0xFFF59E0B), sub: 'field representatives'),
                  ];
                  if (constraints.maxWidth < 500) {
                    return Column(children: [
                      Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
                      const SizedBox(height: 12),
                      Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
                    ]);
                  }
                  return Row(children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[2]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[3]),
                  ]);
                }),
                const SizedBox(height: 20),

                // ── Tabs ──
                _buildTabs(),
                const SizedBox(height: 12),

                // ── Toolbar ──
                _buildToolbar(),
                const SizedBox(height: 12),

                // ── Table ──
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        return Column(children: [
                          if (!isMobile) ...[
                            _buildTableHeader(),
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          ],
                          Expanded(
                            child: _filteredUsers.isEmpty
                              ? const Center(
                                  child: Text('No users found.',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                                )
                              : SingleChildScrollView(
                                  padding: isMobile ? const EdgeInsets.symmetric(vertical: 4) : EdgeInsets.zero,
                                  child: Column(
                                    children: isMobile
                                      ? _filteredUsers.map((u) => _buildUserMobileCard(u)).toList()
                                      : List.generate(_filteredUsers.length, (i) =>
                                          _buildUserRow(
                                            _filteredUsers[i],
                                            i == _filteredUsers.length - 1,
                                          ),
                                        ),
                                  ),
                                ),
                          ),
                        ]);
                      }),
                    ),
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

// ════════════════════════════════════════════════════════════════════════════
// DIALOGS — unchanged
// ════════════════════════════════════════════════════════════════════════════

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
        width: MediaQuery.of(context).size.width < 480 ? MediaQuery.of(context).size.width * 0.92 : 400,
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
        width: MediaQuery.of(context).size.width < 480 ? MediaQuery.of(context).size.width * 0.92 : 400,
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
        width: MediaQuery.of(context).size.width < 480 ? MediaQuery.of(context).size.width * 0.92 : 400,
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
        width: MediaQuery.of(context).size.width < 480 ? MediaQuery.of(context).size.width * 0.92 : 400,
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

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
