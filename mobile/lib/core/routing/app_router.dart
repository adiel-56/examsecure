import 'package:go_router/go_router.dart';
import '../../features/auth/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/student/dashboard/student_shell.dart';
import '../../features/student/exam_details/exam_details_screen.dart';
import '../../features/student/payment/payment_screen.dart';
import '../../features/student/reader/secure_reader_screen.dart';
import '../../features/student/unlock_requests/unlock_request_form_screen.dart';
import '../../features/admin/dashboard/admin_shell.dart';
import '../../features/admin/filieres/filiere_form_screen.dart';
import '../../features/admin/matieres/matiere_form_screen.dart';
import '../../features/admin/exams/exam_form_screen.dart';
import '../../features/admin/payments/manage_payment_config_screen.dart';
import '../../models/purchase.dart';
import '../../models/exam.dart';

/// Navigation avec guards de session/rôle (section 34).
/// Rappel : ces guards ne sont qu'un confort d'UX. La sécurité réelle
/// est toujours revérifiée par Django sur chaque appel API.
class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

      GoRoute(path: '/student', builder: (context, state) => const StudentShell()),
      GoRoute(
        path: '/student/exam/:id',
        builder: (context, state) => ExamDetailsScreen(examId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/student/payment',
        builder: (context, state) => PaymentScreen(exam: state.extra as Exam),
      ),
      GoRoute(
        path: '/student/reader',
        builder: (context, state) => SecureReaderScreen(purchase: state.extra as Purchase),
      ),
      GoRoute(
        path: '/student/unlock-request',
        builder: (context, state) => UnlockRequestFormScreen(purchase: state.extra as Purchase),
      ),

      GoRoute(path: '/admin', builder: (context, state) => const AdminShell()),
      GoRoute(path: '/admin/filiere-form', builder: (context, state) => FiliereFormScreen(existing: state.extra)),
      GoRoute(path: '/admin/matiere-form', builder: (context, state) => MatiereFormScreen(existing: state.extra)),
      GoRoute(path: '/admin/exam-form', builder: (context, state) => ExamFormScreen(existing: state.extra)),
      GoRoute(path: '/admin/payment-config', builder: (context, state) => const ManagePaymentConfigScreen()),
    ],
  );
}
