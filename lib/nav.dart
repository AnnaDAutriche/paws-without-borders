import 'package:go_router/go_router.dart';
import 'package:paws_without_borders/screens/shelters_list_screen.dart';
import 'package:paws_without_borders/screens/shelter_registration_screen.dart';
import 'package:paws_without_borders/screens/shelter_detail_screen.dart';
import 'package:paws_without_borders/screens/animals_list_screen.dart';
import 'package:paws_without_borders/screens/animal_detail_screen.dart';
import 'package:paws_without_borders/screens/shelter_reviews_screen.dart';
import 'package:paws_without_borders/screens/auth_screen.dart';
import 'package:paws_without_borders/screens/shelter_dashboard_screen.dart';
import 'package:paws_without_borders/screens/animal_editor_screen.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/screens/admin_shelter_editor_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider auth) => GoRouter(
        initialLocation: AppRoutes.home,
        refreshListenable: auth,
        redirect: (context, state) {
          final loc = state.uri.toString();
          final isAuthed = auth.isSignedIn;
          final isAuthRoute = loc.startsWith(AppRoutes.auth);
          final isDashboard = loc.startsWith(AppRoutes.dashboard);

          if (isDashboard && !isAuthed) {
            return '${AppRoutes.auth}?from=${Uri.encodeComponent(loc)}';
          }
          if (isAuthRoute && isAuthed) return AppRoutes.dashboard;
          return null;
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(child: SheltersListScreen()),
          ),
          GoRoute(
            path: AppRoutes.auth,
            name: 'auth',
            pageBuilder: (context, state) {
              final from = state.uri.queryParameters['from'];
              return NoTransitionPage(child: AuthScreen(from: from));
            },
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: ShelterDashboardScreen()),
            routes: [
              GoRoute(
                path: 'animal/new',
                name: 'animalNew',
                pageBuilder: (context, state) => const NoTransitionPage(child: AnimalEditorScreen()),
              ),
              GoRoute(
                path: 'animal/:id/edit',
                name: 'animalEdit',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return NoTransitionPage(child: AnimalEditorScreen(animalId: id));
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.registerShelter,
            name: 'registerShelter',
            pageBuilder: (context, state) => const NoTransitionPage(child: ShelterRegistrationScreen()),
          ),
          GoRoute(
            path: '/shelter/:id',
            name: 'shelterDetail',
            pageBuilder: (context, state) {
              final shelterId = state.pathParameters['id']!;
              return NoTransitionPage(child: ShelterDetailScreen(shelterId: shelterId));
            },
          ),
          GoRoute(
            path: '/admin/shelter/:id/edit',
            name: 'adminShelterEdit',
            pageBuilder: (context, state) {
              final shelterId = state.pathParameters['id']!;
              return NoTransitionPage(child: AdminShelterEditorScreen(shelterId: shelterId));
            },
          ),
          GoRoute(
            path: '/shelter/:id/animals',
            name: 'shelterAnimals',
            pageBuilder: (context, state) {
              final shelterId = state.pathParameters['id']!;
              return NoTransitionPage(child: AnimalsListScreen(shelterId: shelterId));
            },
          ),
          GoRoute(
            path: '/shelter/:id/reviews',
            name: 'shelterReviews',
            pageBuilder: (context, state) {
              final shelterId = state.pathParameters['id']!;
              return NoTransitionPage(child: ShelterReviewsScreen(shelterId: shelterId));
            },
          ),
          GoRoute(
            path: '/animal/:id',
            name: 'animalDetail',
            pageBuilder: (context, state) {
              final animalId = state.pathParameters['id']!;
              return NoTransitionPage(child: AnimalDetailScreen(animalId: animalId));
            },
          ),
        ],
      );
}

class AppRoutes {
  static const String home = '/';
  static const String registerShelter = '/register-shelter';
  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
}
