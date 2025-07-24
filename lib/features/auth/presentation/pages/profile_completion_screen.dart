import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/features/auth/presentation/bloc/signin_cubit.dart';
import 'package:udharoo/features/auth/presentation/bloc/auth_session_cubit.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isBSCalendar = true;
  String? _dateError;
  
  @override
  void initState() {
    super.initState();
    _prefillFromGoogleData();
    _dateController.addListener(_validateDate);
  }

  void _prefillFromGoogleData() {
    final authState = context.read<AuthSessionCubit>().state;
    if (authState is AuthSessionAuthenticated && authState.user.displayName != null) {
      final fullName = authState.user.displayName!;
      final nameParts = fullName.split(' ');
      if (nameParts.isNotEmpty) {
        _firstNameController.text = nameParts.first;
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.sublist(1).join(' ');
        }
      }
    }
  }

  void _validateDate() {
    final dateText = _dateController.text;
    if (dateText.isEmpty) {
      setState(() {
        _dateError = null;
      });
      return;
    }

    final error = _getDateValidationError(dateText);
    setState(() {
      _dateError = error;
    });
  }

  String? _getDateValidationError(String dateText) {
    if (dateText.length < 10) {
      return null; // Don't show error while typing
    }

    try {
      final parts = dateText.split('-');
      if (parts.length != 3) {
        return 'Invalid date format';
      }

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Year validation
      if (_isBSCalendar) {
        if (year < 2000 || year > 2100) {
          return 'Year must be between 2000-2100 (BS)';
        }
      } else {
        final currentYear = DateTime.now().year;
        if (year < 1950 || year > currentYear) {
          return 'Year must be between 1950-$currentYear (AD)';
        }
      }

      // Month validation
      if (month < 1 || month > 12) {
        return 'Month must be between 1-12';
      }

      // Day validation
      final maxDays = _getMaxDaysInMonth(year, month, _isBSCalendar);
      if (day < 1 || day > maxDays) {
        return 'Day must be between 1-$maxDays for this month';
      }

      // Age validation
      if (!_isBSCalendar) {
        final selectedDate = DateTime(year, month, day);
        final now = DateTime.now();
        final age = now.year - selectedDate.year;
        if (age < 13) {
          return 'You must be at least 13 years old';
        }
        if (age > 100) {
          return 'Please enter a valid birth year';
        }
      }

      return null;
    } catch (e) {
      return 'Invalid date format';
    }
  }

  int _getMaxDaysInMonth(int year, int month, bool isBSCalendar) {
    if (isBSCalendar) {
      // Simplified BS calendar - you can enhance this with actual BS calendar logic
      switch (month) {
        case 1: case 5: case 7: case 8: case 10: case 12:
          return 31;
        case 3: case 6: case 9: case 11:
          return 30;
        case 2:
          return 32; // BS Falgun typically has 32 days
        case 4:
          return 31; // BS Chaitra
        default:
          return 30;
      }
    } else {
      // Standard Gregorian calendar
      switch (month) {
        case 1: case 3: case 5: case 7: case 8: case 10: case 12:
          return 31;
        case 4: case 6: case 9: case 11:
          return 30;
        case 2:
          return _isLeapYear(year) ? 29 : 28;
        default:
          return 30;
      }
    }
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  DateTime? _parseDate() {
    try {
      final parts = _dateController.text.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        
        if (_isBSCalendar) {
          // For BS dates, you might want to convert to AD
          // For now, we'll store as-is and handle conversion in backend
          return DateTime(year, month, day);
        } else {
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final parsedDate = _parseDate();
      if (parsedDate == null || _dateError != null) {
        CustomToast.show(
          context,
          message: 'Please enter a valid birth date',
          isSuccess: false,
        );
        return;
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();
      
      final signInCubit = context.read<SignInCubit>();
      signInCubit.completeProfile(
        fullName: fullName,
        birthDate: parsedDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<SignInCubit, SignInState>(
      listener: (context, state) {
        switch (state) {
          case ProfileCompleted():
            context.read<AuthSessionCubit>().setUser(state.user);
          case SignInError():
            CustomToast.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          default:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.person_add,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Complete Your Profile',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'We need a few more details to set up your account securely.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                    labelText: 'First Name',
                                    hintText: 'Enter first name',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value?.trim().isEmpty ?? true) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Last Name',
                                    hintText: 'Enter last name',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value?.trim().isEmpty ?? true) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Text(
                            'Birth Date',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _isBSCalendar = true;
                                            _dateController.clear();
                                          });
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<bool>(
                                              value: true,
                                              groupValue: _isBSCalendar,
                                              onChanged: (value) {
                                                setState(() {
                                                  _isBSCalendar = value!;
                                                  _dateController.clear();
                                                });
                                              },
                                              activeColor: theme.colorScheme.primary,
                                            ),
                                            Flexible(
                                              child: Text(
                                                'BS',
                                                style: theme.textTheme.bodySmall,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _isBSCalendar = false;
                                            _dateController.clear();
                                          });
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<bool>(
                                              value: false,
                                              groupValue: _isBSCalendar,
                                              onChanged: (value) {
                                                setState(() {
                                                  _isBSCalendar = value!;
                                                  _dateController.clear();
                                                });
                                              },
                                              activeColor: theme.colorScheme.primary,
                                            ),
                                            Flexible(
                                              child: Text(
                                                'AD',
                                                style: theme.textTheme.bodySmall,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                TextFormField(
                                  controller: _dateController,
                                  decoration: InputDecoration(
                                    hintText: 'YYYY-MM-DD',
                                    prefixIcon: Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                    errorText: _dateError,
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    DateInputFormatter(),
                                  ],
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Birth date is required';
                                    }
                                    if (value!.length != 10) {
                                      return 'Enter complete date (YYYY-MM-DD)';
                                    }
                                    return _getDateValidationError(value);
                                  },
                                ),
                                
                                if (_dateController.text.isNotEmpty && _dateError == null && _dateController.text.length == 10)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Format: ${_isBSCalendar ? 'Bikram Sambat' : 'Anno Domini'} (${_dateController.text})',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your full name and birth date cannot be changed after setup.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          BlocBuilder<SignInCubit, SignInState>(
                            builder: (context, state) {
                              final isLoading = state is SignInLoading;
                              
                              return SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: isLoading ? null : _handleSubmit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        )
                                      : Text(
                                          'Complete Profile',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length > 10) {
      return oldValue;
    }
    
    String formatted = '';
    int selectionIndex = newValue.selection.end;
    
    for (int i = 0; i < text.length; i++) {
      if (i == 4 || i == 6) {
        formatted += '-';
        if (i < selectionIndex) {
          selectionIndex++;
        }
      }
      formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}