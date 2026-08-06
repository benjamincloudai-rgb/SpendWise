import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/core/theme/app_colors.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/profile/domain/profile_avatars.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isSaving = false;
  String _avatarKey = defaultProfileAvatarKey;
  String _email = '';

  // Strict colors matching the SpendWise design system
  final Color colorPrimary = AppColors.primary;
  final Color colorPrimaryContainer = AppColors.primaryContainer;
  final Color colorBackground = AppColors.background;
  final Color colorSurfaceContainerLowest = AppColors.surfaceContainerLowest;
  final Color colorSurfaceContainerLow = AppColors.surfaceContainerLow;
  final Color colorOnSurfaceVariant = AppColors.onSurfaceVariant;
  final Color colorOnSurface = AppColors.onSurface;
  final Color colorPrimaryFixed = AppColors.primaryFixed;
  final Color colorSecondaryFixed = AppColors.secondaryFixed;
  final Color colorOutlineVariant = AppColors.outlineVariant;

  // Secondary and Error colors matching specs
  final Color colorSecondary = AppColors.secondary;
  final Color colorTertiary = AppColors.tertiary;
  final Color colorError = AppColors.error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final rawName = data?['fullName'];
      final rawAvatarKey = data?['avatarKey'];
      if (mounted) {
        setState(() {
          _nameController.text =
              rawName is String && rawName.trim().isNotEmpty ? rawName : '';
          _avatarKey =
              rawAvatarKey is String && rawAvatarKey.isNotEmpty
                  ? rawAvatarKey
                  : defaultProfileAvatarKey;
          _email = user.email ?? '';
        });
      }
    } catch (_) {
      // Fall back to defaults so the form stays editable offline.
      if (mounted) {
        setState(() {
          _avatarKey = defaultProfileAvatarKey;
          _email = user.email ?? '';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to update.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'fullName': _nameController.text.trim(),
          'avatarKey': _avatarKey,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with other screens) ---
            Positioned(
              top: -100,
              right: -100,
              child: BlurBlob(
                color: colorPrimaryFixed.withValues(alpha: 0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: BlurBlob(
                color: colorSecondaryFixed.withValues(alpha: 0.2),
                size: 400,
                blur: 80,
              ),
            ),

            // --- Scrollable Form Content ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: 76, // Clears top sticky App Bar
                  bottom: 40, // Secure padding at the bottom
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 16),
                                EntranceAnimation(
                                  delayMs: 100,
                                  child: _buildAvatarCard(),
                                ),
                                const SizedBox(height: 24),
                                EntranceAnimation(
                                  delayMs: 180,
                                  child: _buildFormCard(),
                                ),
                                const SizedBox(height: 24),
                                EntranceAnimation(
                                  delayMs: 240,
                                  child: _buildSaveButton(),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // --- Sticky Top App Bar ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EntranceAnimation(
                delayMs: 50,
                child: _buildHeader(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Component (Sticky Top App Bar)
  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      color: colorBackground.withValues(alpha: 0.95),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorOnSurface, size: 28),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Text(
                'Edit Profile',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorSecondary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Avatar preview card with the selection ring and edit badge
  Widget _buildAvatarCard() {
    final avatar = profileAvatarFor(_avatarKey);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorSurfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: profileAvatarDecoration(
                  _avatarKey,
                  ringColor: colorPrimaryContainer,
                  ringWidth: 4,
                ),
                child: Icon(avatar.icon, size: 48, color: avatar.color),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorSurfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.edit, size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choose your avatar',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap an avatar below to select it',
            style: GoogleFonts.inter(fontSize: 13, color: colorSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: profileAvatarOptions.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final option = profileAvatarOptions[index];
                final isSelected = option.key == _avatarKey;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _avatarKey = option.key;
                    });
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: option.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colorPrimary, width: 2.5)
                          : null,
                    ),
                    child: Icon(
                      option.icon,
                      color: isSelected ? option.color : colorSecondary,
                      size: 26,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Form card with name and read-only email fields
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorSurfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Full Name',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            maxLength: 50,
            textInputAction: TextInputAction.done,
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Please enter your name.';
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter your full name...',
              hintStyle: GoogleFonts.inter(
                color: colorTertiary,
                fontSize: 14,
              ),
              counterText: '',
              prefixIcon: Icon(
                Icons.person_outline,
                color: colorOnSurfaceVariant,
                size: 22,
              ),
              filled: true,
              fillColor: colorSurfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorPrimary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorError, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorError, width: 2),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14, color: colorOnSurface),
          ),
          const SizedBox(height: 24),
          Text(
            'Email Address',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _email,
            enabled: false,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.mail_outline,
                color: colorOnSurfaceVariant,
                size: 22,
              ),
              filled: true,
              fillColor: colorSurfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorOnSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Email cannot be changed here.',
            style: GoogleFonts.inter(fontSize: 12, color: colorSecondary),
          ),
        ],
      ),
    );
  }

  // Save button with loading state
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 1,
      ),
      child: _isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(
              'Save Changes',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
