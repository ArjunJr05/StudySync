import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/commons/widgets/k_text.dart';
import 'package:studysync/commons/widgets/k_vertical_spacer.dart';
import 'package:studysync/core/constants/app_router_constants.dart';
import 'package:studysync/core/services/firestore_service.dart';
import 'package:studysync/core/themes/app_colors.dart';
import 'package:studysync/features/verfication/presentation/widgets/form_navigator.dart';
import 'package:studysync/features/verfication/presentation/widgets/recommandation.dart';

class StudentVerify extends StatefulWidget {
  const StudentVerify({super.key});

  @override
  State<StudentVerify> createState() => _StudentVerifyState();
}

class _StudentVerifyState extends State<StudentVerify>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _teacherController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<String> _institutionSuggestions = [];
  List<String> _teacherSuggestions = [];
  bool _isLoadingTeachers = false;
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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
  }

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

  void _fetchTeachers(String institutionName) async {
    if (institutionName.isEmpty) return;
    setState(() {
      _isLoadingTeachers = true;
      _teacherSuggestions = [];
    });
    final names = await FirestoreService.getTeacherNamesForInstitution(
      institutionName,
    );
    if (mounted) {
      setState(() {
        _teacherSuggestions = names;
        _isLoadingTeachers = false;
      });
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _teacherController.dispose();
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
            text: "Almost There!",
            fontSize: 28,
            fontWeight: FontWeight.bold,
            textColor: AppColors.primaryColor,
          ),
          const KVerticalSpacer(height: 8),
          KText(
            text: "Help us connect you with your teacher",
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
        EnhancedAutocompleteField(
          controller: _institutionController,
          label: "Institution Name",
          hint: "Start typing your school/college name",
          icon: Icons.school,
          suggestions: _institutionSuggestions,
          isLoading: _isLoadingInstitutions,
          onSelected: (selection) {
            _teacherController.clear();
            _fetchTeachers(selection);
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your institution name';
            }
            // Ensure student selects from a valid, existing institution
            if (!_institutionSuggestions.contains(value)) {
              return 'Please select a valid institution from the list';
            }
            return null;
          },
        ),
        const KVerticalSpacer(height: 24),
        EnhancedAutocompleteField(
          controller: _teacherController,
          label: "Teacher Name",
          hint: _institutionController.text.isEmpty
              ? "Select an institution first"
              : "Start typing your teacher's name",
          icon: Icons.person,
          suggestions: _teacherSuggestions,
          enabled: _institutionController.text.isNotEmpty,
          isLoading: _isLoadingTeachers,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Please enter your teacher's name";
            }
            // Ensure student selects a valid teacher from the chosen institution
            if (!_teacherSuggestions.contains(value)) {
              return 'Please select a valid teacher from the list';
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
          child: const KText(
            text: "Continue",
            fontSize: 16,
            fontWeight: FontWeight.w600,
            textColor: Colors.white,
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    FormNavigationHandler.handleStudentContinue(
      context: context,
      formKey: _formKey,
      institutionController: _institutionController,
      teacherController: _teacherController,
    );
  }
}
