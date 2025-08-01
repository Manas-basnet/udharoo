import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:udharoo/config/routes/routes_constants.dart';
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/contacts/presentation/widgets/add_contact_dialog.dart';
import 'package:udharoo/features/contacts/presentation/widgets/contact_list_item.dart';
import 'package:udharoo/shared/presentation/widgets/custom_toast.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactCubit>().loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    final horizontalPadding = _getResponsiveHorizontalPadding(screenWidth);
    final expandedHeight = _calculateExpandedHeight(screenHeight, topPadding);

    return BlocConsumer<ContactCubit, ContactState>(
      listener: (context, state) {
        if (state is ContactDeleteSuccess) {
          CustomToast.show(
            context,
            message: 'Contact deleted successfully',
            isSuccess: true,
          );
          context.read<ContactCubit>().clearMessages();
        } else if (state is ContactError) {
          CustomToast.show(
            context,
            message: state.message,
            isSuccess: false,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              await context.read<ContactCubit>().loadContacts();
              await context.read<ContactCubit>().refreshContactTransactionCounts();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(theme, horizontalPadding, expandedHeight, state),
                _buildQuickActions(theme, horizontalPadding),
                _buildSearchSection(theme, horizontalPadding),
                _buildContactsSliver(state, theme, horizontalPadding),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < 360) return 12.0;
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 840) return 24.0;
    return 32.0;
  }

  double _calculateExpandedHeight(double screenHeight, double topPadding) {
    final additionalHeight = (screenHeight * 0.16);
    return additionalHeight;
  }

  Widget _buildSliverAppBar(ThemeData theme, double horizontalPadding, double expandedHeight, ContactState state) {
    final contacts = _getContactsFromState(state);
    
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: horizontalPadding,
      title: Text(
        'Contacts',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
          fontSize: 24,
        ),
      ),
      actions: [
        _buildActionButton(
          icon: Icons.person_add_rounded,
          tooltip: 'Add Contact',
          theme: theme,
          onPressed: () => _showAddContactDialog(context),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.qr_code_scanner_rounded,
          tooltip: 'Scan QR',
          theme: theme,
          onPressed: () {
            // TODO: Implement QR scanner for adding contacts
          },
        ),
        SizedBox(width: horizontalPadding),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Container(
            color: theme.colorScheme.surface,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              kToolbarHeight + 12,
              horizontalPadding,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.people_rounded,
                        color: theme.colorScheme.primary,
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Manage your transaction contacts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${contacts.length} contacts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required ThemeData theme,
    required VoidCallback onPressed,
  }) {
    Color backgroundColor;
    
    switch (tooltip) {
      case 'Add Contact':
        backgroundColor = theme.colorScheme.primary;
        break;
      case 'Scan QR':
        backgroundColor = Colors.green;
        break;
      default:
        backgroundColor = theme.colorScheme.primary;
    }
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, double horizontalPadding) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.06),
              theme.colorScheme.primary.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.person_add_rounded,
                    label: 'Add Contact',
                    onTap: () => _showAddContactDialog(context),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR',
                    onTap: () {
                      // TODO: Implement QR scanner
                    },
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.import_contacts_rounded,
                    label: 'Import',
                    onTap: () {
                      // TODO: Implement contact import
                    },
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme, double horizontalPadding) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SearchSliverDelegate(
        theme: theme,
        horizontalPadding: horizontalPadding,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ContactCubit>().clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (query) {
                setState(() {});
                if (query.trim().isEmpty) {
                  context.read<ContactCubit>().clearSearch();
                } else {
                  context.read<ContactCubit>().searchContacts(query);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsSliver(ContactState state, ThemeData theme, double horizontalPadding) {
    if (state is ContactLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is ContactError && 
        state is! ContactSearchResults && 
        state is! ContactLoaded &&
        state is! ContactTransactionCountUpdated &&
        state is! ContactSearchTransactionCountUpdated) {
      return SliverFillRemaining(
        child: _buildErrorState(state.message, theme),
      );
    }

    final contacts = _getContactsFromState(state);
    final isSearchResult = state is ContactSearchResults || state is ContactSearchTransactionCountUpdated;

    if (contacts.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(theme, isSearchResult),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final contact = contacts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ContactListItem(
                contact: contact,
                onTap: () => _navigateToContactTransactions(contact),
              ),
            );
          },
          childCount: contacts.length,
        ),
      ),
    );
  }

  List<Contact> _getContactsFromState(ContactState state) {
    return switch (state) {
      ContactLoaded(:final contacts) => contacts,
      ContactSearchResults(:final contacts) => contacts,
      ContactTransactionCountUpdated(:final contacts) => contacts,
      ContactSearchTransactionCountUpdated(:final contacts) => contacts,
      _ => <Contact>[],
    };
  }

  Widget _buildEmptyState(ThemeData theme, bool isSearchResult) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchResult ? Icons.search_off : Icons.person_add_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isSearchResult ? 'No Results Found' : 'No Contacts Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchResult
                  ? 'Try different keywords or check your spelling'
                  : 'Add your first contact to start managing transactions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearchResult) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddContactDialog(context),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add Contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                context.read<ContactCubit>().loadContacts();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ContactCubit>()),
        ],
        child: const AddContactDialog(),
      ),
    );
  }

  void _navigateToContactTransactions(Contact contact) {
    context.push(Routes.contactTransactions, extra: contact);
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchSliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ThemeData theme;
  final double horizontalPadding;

  _SearchSliverDelegate({
    required this.child,
    required this.theme,
    required this.horizontalPadding,
  });

  @override
  double get minExtent => 72.0;

  @override
  double get maxExtent => 72.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}