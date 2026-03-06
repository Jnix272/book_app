import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:booking/providers/auth_provider.dart';
import 'package:booking/core/app_initializer.dart';
import 'package:booking/features/main/screen/customer_screen.dart';

import '../app_theme.dart';
import '../auth/welcome_screen.dart';
import '../auth/customer_login_screen.dart';
import '../auth/provider_login_screen.dart';
import '../auth/customer_signup_screen.dart';
import '../auth/provider_signup_screen.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/splash_screen.dart';
import '../auth/email_verification_screen.dart';
import '../features/booking/screen/provider_detail_screen.dart';
import '../features/booking/screen/booking_slot_screen.dart';
import '../features/booking/screen/booking_confirmed_screen.dart';
import '../features/appointments/screen/appointments_screen.dart';
import '../features/profile/screen/profile_screen.dart';
import '../features/provider/screen/provider_shell.dart';
import '../features/search/screen/search_screen.dart';
import '../models/models.dart';

// ─── Navigator key ─────────────────────────────────────────────────────────────
final GlobalKey<NavigatorState> routerKey = GlobalKey<NavigatorState>();

// ─── Auth-only routes: logged-in users bounce away ────────────────────────────
const Set<String> _authRoutes = {
  '/customer_login',
  '/provider_login',
  '/customer_signup',
  '/provider_signup',
  '/forgot_password',
  '/splash',
  '/front',
  '/email_verify',
};

// ─── Protected routes: unauthenticated users bounce to /front ─────────────────
const Set<String> _protectedRoutes = {
  '/booking_slot',
  '/booking_confirm',
  '/booking_confirmed',
  '/appointment_detail',
  '/profile',
  '/reschedule',
  '/provider_dashboard',
};

String _homeForRole(String role) =>
    role == 'provider' ? '/provider_dashboard' : '/';

// ──────────────────────────────────────────────────────────────────────────────

final GoRouter router = GoRouter(
  navigatorKey: routerKey,
  // Rebuild the router whenever the authProvider emits a new state.
  // AuthStateListenable wraps the AuthNotifier so GoRouter can listen to it.
  refreshListenable: AuthStateListenable(container.read(authProvider.notifier)),
  initialLocation: '/splash',

  redirect: (context, state) {
    final authState = container.read(authProvider);
    final location = state.matchedLocation;

    // Still initializing — hold on splash
    if (authState is AuthInitial || authState is AuthLoading) return '/splash';

    // Auth is fully resolved from here down
    final loggedIn = authState is AuthAuthenticated;
    final role = switch (authState) {
      AuthAuthenticated(role: final r) => r,
      _ => 'customer',
    };

    // Once auth is resolved, /splash must always redirect.
    if (location == '/splash') {
      return loggedIn ? _homeForRole(role) : '/front';
    }

    // Logged-in users should not visit auth screens
    if (loggedIn && _authRoutes.contains(location)) {
      return _homeForRole(role);
    }

    // Unauthenticated users cannot visit protected routes
    final isProtected = _protectedRoutes.any(
      (p) => location == p || location.startsWith('$p/'),
    );
    if (!loggedIn && isProtected) return '/front';

    return null;
  },

  errorBuilder: (context, state) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'Page not found',
            style: TextStyle(color: AppColors.ink, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Go home'),
          ),
        ],
      ),
    ),
  ),

  routes: [
    // ── Utility ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SplashScreen()),
    ),
    GoRoute(path: '/front', builder: (context, state) => const WelcomeScreen()),

    // ── Auth ───────────────────────────────────────────────────────────────
    GoRoute(
      path: '/customer_login',
      builder: (context, state) => const CustomerSignInScreen(),
    ),
    GoRoute(
      path: '/provider_login',
      builder: (context, state) => const ProviderSignInScreen(),
    ),
    GoRoute(
      path: '/customer_signup',
      builder: (context, state) => const CustomerSignupScreen(),
    ),
    GoRoute(
      path: '/provider_signup',
      builder: (context, state) => const ProviderSignupScreen(),
    ),
    GoRoute(
      path: '/forgot_password',
      builder: (context, state) {
        final accentColor = state.extra as Color? ?? AppColors.sage;
        return ForgotPasswordScreen(accentColor: accentColor);
      },
    ),
    GoRoute(
      path: '/email_verify',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        final email = extras['email'] as String;
        final roleStr = extras['role'] as String? ?? 'customer';
        final role = roleStr == 'provider'
            ? AuthRole.provider
            : AuthRole.customer;
        return EmailVerificationScreen(email: email, role: role);
      },
    ),

    // ── Customer ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final initialTab = extras?['tab'] as int? ?? 0;
        return CustomerScreen(initialTab: initialTab);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final query = state.extra as String? ?? '';
        return SearchScreen(initialQuery: query);
      },
    ),
    GoRoute(
      path: '/provider',
      builder: (context, state) {
        final provider = state.extra as ServiceProvider;
        return ProviderDetailScreen(provider: provider);
      },
    ),
    GoRoute(
      path: '/booking_slot',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return BookingSlotScreen(
          provider: extras['provider'] as ServiceProvider,
          service: extras['service'] as ServiceType,
        );
      },
    ),
    GoRoute(
      path: '/booking_confirm',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return BookingConfirmScreen(
          provider: extras['provider'] as ServiceProvider,
          service: extras['service'] as ServiceType,
          date: extras['date'] as DateTime,
          slot: extras['slot'] as String,
        );
      },
    ),
    GoRoute(
      path: '/booking_confirmed',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return BookingConfirmedScreen(
          provider: extras['provider'] as ServiceProvider,
          service: extras['service'] as ServiceType,
          date: extras['date'] as DateTime,
          slot: extras['slot'] as String,
          appointmentId: extras['appointmentId'] as String,
        );
      },
    ),
    GoRoute(
      path: '/appointment_detail',
      builder: (context, state) {
        final appointment = state.extra as Appointment;
        return AppointmentDetailScreen(appointment: appointment);
      },
    ),
    GoRoute(
      path: '/reschedule',
      builder: (context, state) {
        final appointment = state.extra as Appointment;
        return RescheduleScreen(appointment: appointment);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // ── Provider ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/provider_dashboard',
      builder: (context, state) => const ProviderShell(),
    ),
  ],
);
