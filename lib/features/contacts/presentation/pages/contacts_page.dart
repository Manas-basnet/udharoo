import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:udharoo/core/di/di.dart' as di;
import 'package:udharoo/features/contacts/domain/entities/contact.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:udharoo/features/contacts/presentation/bloc/contact_transactions/contact_transactions_cubit.dart';
import 'package:udharoo/features/contacts/presentation/pages/contact_transactions_page.dart';
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
    final horizontalPadding = _getResponsiveHorizontalPadding(screenWidth);

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
              context.read<ContactCubit>().loadContacts();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(theme, horizontalPadding),
                _buildSearchSliver(theme, horizontalPadding),
                _buildContactsSliver(state, theme, horizontalPadding),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddContactDialog(context),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: const Icon(Icons.person_add_rounded),
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

  Widget _buildSliverAppBar(ThemeData theme, double horizontalPadding) {
    return SliverAppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: 120,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: horizontalPadding,
      title: Text(
        'Contacts',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showAddContactDialog(context),
          icon: const Icon(Icons.person_add_rounded, size: 24),
          tooltip: 'Add Contact',
        ),
        SizedBox(width: horizontalPadding),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Container(
            color: theme.colorScheme.surface,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              kToolbarHeight + 16,
              horizontalPadding,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Manage your transaction contacts',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSliver(ThemeData theme, double horizontalPadding) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SearchSliverDelegate(
        theme: theme,
        horizontalPadding: horizontalPadding,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 12,
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
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ContactCubit>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
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

    if (state is ContactError && state is! ContactSearchResults && state is! ContactLoaded) {
      return SliverFillRemaining(
        child: _buildErrorState(state.message, theme),
      );
    }

    final contacts = switch (state) {
      ContactLoaded(:final contacts) => contacts,
      ContactSearchResults(:final contacts) => contacts,
      _ => <Contact>[],
    };

    if (contacts.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(theme, state is ContactSearchResults),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final contact = contacts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildEmptyState(ThemeData theme, bool isSearchResult) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchResult ? Icons.search_off : Icons.person_add_outlined,
              size: 64,
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
              FilledButton.icon(
                onPressed: () => _showAddContactDialog(context),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add Contact'),
                style: FilledButton.styleFrom(
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
              size: 64,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => di.sl<ContactTransactionsCubit>(),
          child: ContactTransactionsPage(contact: contact),
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
  double get minExtent => 80.0;

  @override
  double get maxExtent => 80.0;

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