import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/constants/app_router_constants.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/verfication/presentation/widgets/customer_input_field.dart';
import 'package:studysync/features/verfication/presentation/widgets/form_navigator.dart';
import 'package:studysync/features/verfication/presentation/widgets/recommandation.dart';

class TeacherVerify extends StatefulWidget {
  const TeacherVerify({super.key});

  @override
  State<TeacherVerify> createState() => _TeacherVerifyState();
}

class _TeacherVerifyState extends State<TeacherVerify>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _teacherNameController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // NEW: State for institution autocomplete
  List<String> _institutionSuggestions = [];
  bool _isLoadingInstitutions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchInstitutions();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  // NEW: Method to fetch institution names for the autocomplete field
  void _fetchInstitutions() async {
    setState(() => _isLoadingInstitutions = true);
    final names = await FirestoreService.getAllInstitutionNames();
    if (mounted) {
      setState(() {
        _institutionSuggestions = names;
        _isLoadingInstitutions = false;
      });
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _teacherNameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgLightColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryColor),
          onPressed: () => GoRouter.of(context).goNamed(AppRouterConstants.findingUser),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KVerticalSpacer(height: 20),
                      _buildHeader(),
                      const KVerticalSpacer(height: 40),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildFormFields(),
                          ),
                        ),
                      ),
                      _buildContinueButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KText(
            text: "Welcome Teacher!",
            fontSize: 28,
            fontWeight: FontWeight.bold,
            textColor: AppColors.primaryColor,
          ),
          const KVerticalSpacer(height: 8),
          KText(
            text: "Help us create your profile",
            fontSize: 16,
            textColor: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        CustomInputField(
          controller: _teacherNameController,
          label: "Your Name",
          hint: "Enter your full name",
          icon: Icons.person,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        const KVerticalSpacer(height: 24),
        // MODIFIED: Using the enhanced autocomplete field for institutions
        EnhancedAutocompleteField(
          controller: _institutionController,
          label: "Institution Name",
          hint: "Start typing your school/college name",
          icon: Icons.account_balance,
          suggestions: _institutionSuggestions,
          isLoading: _isLoadingInstitutions,
          // Teachers can create new institutions, so no strict validation needed here
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your institution name';
            }
            if (value.trim().length < 3) {
              return 'Institution name must be at least 3 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.only(bottom: 30),
        child: ElevatedButton(
          onPressed: _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KText(
                text: "Continue",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                textColor: Colors.white,
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    FormNavigationHandler.handleTeacherContinue(
      context: context,
      formKey: _formKey,
      institutionController: _institutionController,
      teacherNameController: _teacherNameController,
    );
  }
}