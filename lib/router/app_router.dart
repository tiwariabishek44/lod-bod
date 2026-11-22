import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../core/providers/core_providers.dart';
import '../features/analytics/ui/analytics_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/otp_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/home/ui/home_screen.dart';
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/profile/ui/profile_screen.dart';
import '../features/shipments/ui/create_shipment_screen.dart';
import '../features/shipments/ui/shipment_details_screen.dart';
import '../features/shipments/ui/shipments_screen.dart';
import '../features/splash/ui/splash_screen.dart';
import '../features/onboarding/providers/onboarding_provider.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authStateProvider.notifier);
  final router = GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: authNotifier,
    redirect: (context, routeState) {
      final location = routeState.matchedLocation;
      final isAuthenticated = ref.read(authStateProvider).isAuthenticated;
      final hasCompletedOnboarding = ref
          .read(preferencesStoreProvider)
          .hasCompletedOnboarding;

      if (location == RouteNames.splash) return null;

      if (!hasCompletedOnboarding) {
        return location == RouteNames.onboarding ? null : RouteNames.onboarding;
      }

      if (location == RouteNames.onboarding) {
        return isAuthenticated ? RouteNames.home : RouteNames.login;
      }

      final isAuthRoute =
          location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.otp;
      final isAppRoute =
          location == RouteNames.home ||
          location == RouteNames.shipments ||
          location.startsWith('${RouteNames.shipments}/') ||
          location == RouteNames.analytics ||
          location == RouteNames.profile;

      if (!isAuthenticated && isAppRoute) return RouteNames.login;
      if (isAuthenticated && isAuthRoute) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => LodbodSplashScreen(
          onComplete: () {
            final completedOnboarding = ref.read(onboardingControllerProvider);
            final isAuthenticated = ref.read(authStateProvider).isAuthenticated;
            context.go(
              !completedOnboarding
                  ? RouteNames.onboarding
                  : isAuthenticated
                  ? RouteNames.home
                  : RouteNames.login,
            );
          },
        ),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => OnboardingScreen(
          onComplete: () async {
            await ref.read(onboardingControllerProvider.notifier).complete();
            if (!context.mounted) return;
            context.go(
              ref.read(authStateProvider).isAuthenticated
                  ? RouteNames.home
                  : RouteNames.login,
            );
          },
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final path = state.uri.path;
          final showBottomNavigation =
              path == RouteNames.home ||
              path == RouteNames.shipments ||
              path == RouteNames.analytics ||
              path == RouteNames.profile;
          return AppShell(
            navigationShell: navigationShell,
            showBottomNavigation: showBottomNavigation,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.shipments,
                builder: (context, state) => const ShipmentsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => CreateShipmentScreen(
                      resumeDraft:
                          state.uri.queryParameters['resumeDraft'] == '1',
                    ),
                  ),
                  GoRoute(
                    path: ':shipmentId',
                    builder: (context, state) => ShipmentDetailsScreen(
                      shipmentId: state.pathParameters['shipmentId']!,
                      showBidsOnOpen:
                          state.uri.queryParameters['reviewBids'] == '1',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.analytics,
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
