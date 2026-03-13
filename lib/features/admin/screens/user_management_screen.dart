import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/widgets/responsive_shell.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({
    super.key,
    required this.database,
    required this.syncManager,
  });
  final AppDatabase database;
  final SyncManager syncManager;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String _selectedRole = 'All Roles';
  bool _isLoading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await widget.database.getAllUsers();
      final userList = users
          .where((user) => !user.isDeleted)
          .map((user) => User(
                id: user.id,
                firstName: user.firstName,
                lastName: user.lastName,
                email: user.email,
                role: user.role,
                isActive: user.isActive,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt,
              ))
          .toList();
      
      setState(() {
        _users = userList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _users = _users.where((user) {
        final matchesSearch = user.fullName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesRole = _selectedRole == 'All Roles' || user.role == _selectedRole;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        database: widget.database,
        onSave: _loadUsers,
      ),
    );
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        database: widget.database,
        user: user,
        onSave: _loadUsers,
      ),
    );
  }

  void _toggleUserStatus(User user) async {
    try {
      final updatedUser = user.copyWith(
        isActive: !user.isActive,
        updatedAt: DateTime.now(),
      );
      
      await widget.database.updateUser(user.id, {
        'isActive': updatedUser.isActive,
        'updatedAt': updatedUser.updatedAt,
      });
      
      _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(user.isActive ? 'User deactivated' : 'User activated'),
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

  void _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.database.updateUser(user.id, {
          'isDeleted': true,
          'updatedAt': DateTime.now(),
        });
        
        _loadUsers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF1E1E1E);
      case 'warehouse':
        return const Color(0xFF424242);
      case 'delivery':
        return const Color(0xFF616161);
      case 'customer':
        return const Color(0xFFE0E0E0);
      case 'pending':
        return const Color(0xFFFFF3E0);
      default:
        return Colors.grey;
    }
  }

  Color _getRoleTextColor(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return const Color(0xFF1E1E1E);
      case 'pending':
        return const Color(0xFFE65100);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      database: widget.database,
      selectedRoute: '/admin/users',
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Accounts',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage system users',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddUserDialog,
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search and Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _searchController.text = value;
                        _filterUsers();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 180,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        onChanged: (value) {
                          _selectedRole = value!;
                          _filterUsers();
                        },
                        items: const [
                          'All Roles',
                          'admin',
                          'warehouse',
                          'delivery',
                          'customer',
                          'pending',
                        ].map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Users Table
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _users.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B6B6B),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF9F9F9),
                                    border: Border(
                                      bottom: BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 25,
                                        child: Text(
                                          'NAME',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B6B6B),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 30,
                                        child: Text(
                                          'EMAIL',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B6B6B),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text(
                                          'ROLE',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B6B6B),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text(
                                          'STATUS',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B6B6B),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text(
                                          'ACTIONS',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B6B6B),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Data Rows
                                ..._users.map((user) => _buildUserRow(user)),
                              ],
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

  Widget _buildUserRow(User user) {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Name with avatar
              Expanded(
                flex: 25,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Email
              Expanded(
                flex: 30,
                child: Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Role
              Expanded(
                flex: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getRoleTextColor(user.role),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Status
              Expanded(
                flex: 15,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: user.isActive ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: user.isActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Expanded(
                flex: 15,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _showEditUserDialog(user),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit User',
                    ),
                    IconButton(
                      onPressed: () => _toggleUserStatus(user),
                      icon: Icon(
                        user.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                        size: 18,
                      ),
                      tooltip: user.isActive ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      onPressed: () => _deleteUser(user),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'Delete User',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_users.last != user)
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }
}

class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String get fullName => '$firstName $lastName';
  final String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class _UserDialog extends StatefulWidget {
  const _UserDialog({
    super.key,
    required this.database,
    this.user,
    required this.onSave,
  });
  final AppDatabase database;
  final User? user;
  final VoidCallback onSave;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'customer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _firstNameController.text = widget.user!.firstName;
      _lastNameController.text = widget.user!.lastName;
      _emailController.text = widget.user!.email;
      _selectedRole = widget.user!.role;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.user == null) {
        // Create new user
        final newUser = {
          'id': const Uuid().v4(),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'passwordHash': _hashPassword(_passwordController.text),
          'syncStatus': 'pending',
          'isActive': true,
          'isDeleted': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        await widget.database.customInsert('users', newUser);
      } else {
        // Update existing user
        final updates = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        // Only update password if provided
        if (_passwordController.text.isNotEmpty) {
          updates['passwordHash'] = _hashPassword(_passwordController.text);
        }
        
        await widget.database.customUpdate(
          'users',
          widget.user!.id,
          updates,
        );
      }
      
      widget.onSave();
      Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.user == null ? 'User created successfully' : 'User updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving user: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user == null ? 'Add User' : 'Edit User',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.user == null ? 'Password' : 'Password (leave empty to keep current)',
                  border: OutlineInputBorder(),
                ),
                validator: widget.user == null
                    ? (value) => value?.isEmpty ?? true ? 'Required' : null
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'warehouse', child: Text('Warehouse')),
                  DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveUser,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
