import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avalia_pro/features/access/access_screen.dart';
import 'package:avalia_pro/features/access/data/auth_repository.dart';
import 'package:avalia_pro/features/access/data/user_profile.dart';
import 'package:avalia_pro/features/access/view_models/auth_view_model.dart';
import 'package:avalia_pro/features/config/config_screen.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('creates UserProfile and serializes to Map', () {
      final now = DateTime(2026, 10, 20);
      final profile = UserProfile(
        uid: 'user-123',
        name: 'Prof. Carlos',
        email: 'carlos@escola.com.br',
        school: 'Escola Modelo',
        accessCode: 'PROF-1234',
        isAnonymous: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.displayName, 'Prof. Carlos');
      final map = profile.toMap();
      expect(map['name'], 'Prof. Carlos');
      expect(map['email'], 'carlos@escola.com.br');
      expect(map['school'], 'Escola Modelo');
      expect(map['accessCode'], 'PROF-1234');
      expect(map['isAnonymous'], false);
    });

    test('UserProfile copyWith updates fields correctly', () {
      const profile = UserProfile(
        uid: 'user-1',
        name: 'Maria',
        email: 'maria@test.com',
        accessCode: 'PROF-0001',
      );

      final updated = profile.copyWith(
        name: 'Maria Silva',
        accessCode: 'PROF-9999',
      );

      expect(updated.name, 'Maria Silva');
      expect(updated.accessCode, 'PROF-9999');
      expect(updated.email, 'maria@test.com');
      expect(updated.uid, 'user-1');
    });

    test('displayName returns fallback when name is empty', () {
      const profile = UserProfile(
        uid: 'user-2',
        name: '',
        email: 'test@escola.com',
      );

      expect(profile.displayName, 'Professor');
    });
  });

  group('AuthViewModel Validation Tests', () {
    test('signIn rejects invalid or empty email', () async {
      final viewModel = AuthViewModel();

      final resultEmpty = await viewModel.signIn(email: '', password: 'secret');
      expect(resultEmpty, isFalse);
      expect(viewModel.errorMessage, contains('e-mail válido'));

      final resultNoAt = await viewModel.signIn(
        email: 'invalid-email',
        password: 'secret',
      );
      expect(resultNoAt, isFalse);
      expect(viewModel.errorMessage, contains('e-mail válido'));
    });

    test('signIn rejects empty password', () async {
      final viewModel = AuthViewModel();

      final result = await viewModel.signIn(
        email: 'test@escola.com',
        password: '',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('Informe sua senha'));
    });

    test('signUp validates name, email, password length, and confirmation', () async {
      final viewModel = AuthViewModel();

      // Empty name
      var result = await viewModel.signUp(
        name: '',
        email: 'prof@test.com',
        password: '123456',
        confirmPassword: '123456',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('nome completo'));

      // Invalid email
      result = await viewModel.signUp(
        name: 'Prof. Ana',
        email: 'ana-email',
        password: '123456',
        confirmPassword: '123456',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('e-mail válido'));

      // Weak password (< 6 chars)
      result = await viewModel.signUp(
        name: 'Prof. Ana',
        email: 'ana@test.com',
        password: '123',
        confirmPassword: '123',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('pelo menos 6 caracteres'));

      // Non-matching password confirmation
      result = await viewModel.signUp(
        name: 'Prof. Ana',
        email: 'ana@test.com',
        password: '123456',
        confirmPassword: '654321',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('não coincidem'));
    });

    test('sendPasswordReset rejects invalid email', () async {
      final viewModel = AuthViewModel();

      final result = await viewModel.sendPasswordReset('invalid-email');
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('e-mail cadastrado'));
    });
  });

  group('AccessCode Generator Test', () {
    test('generateAccessCode formats correctly', () {
      final code = AuthRepository.generateAccessCode();
      expect(code, startsWith('PROF-'));
      expect(code.length, 9);
      final digits = code.split('-').last;
      expect(int.tryParse(digits), isNotNull);
    });
  });

  group('AccessScreen Widget Tests', () {
    testWidgets('renders sign-in form by default and toggles to sign-up', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AccessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: Sign In
      expect(find.text('Acesse sua conta'), findsOneWidget);
      expect(find.text('E-mail institucional ou pessoal'), findsOneWidget);
      expect(find.text('Acesso rápido como convidado'), findsOneWidget);

      // Switch to sign up
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      // In Sign Up
      expect(find.text('Cadastre-se como professor'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);
      expect(find.text('Cadastrar e começar'), findsOneWidget);
    });

    testWidgets('shows validation error when logging in with empty fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AccessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Entrar with empty fields
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe um endereço de e-mail válido.'), findsOneWidget);
    });
  });

  group('ConfigScreen Widget Tests', () {
    testWidgets('renders profile and logout options in ConfigScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConfigScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Acesso e código institucional'), findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);

      // Expand Access Code panel
      await tester.tap(find.text('Acesso e código institucional'));
      await tester.pumpAndSettle();

      expect(find.text('Código de acesso do professor'), findsOneWidget);
      expect(find.text('Visualizar'), findsOneWidget);
    });
  });
}
