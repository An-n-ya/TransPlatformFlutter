// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_mutation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentMutationHash() => r'11379c2002c67692983945826502966cc92e6aa9';

/// Optimistic comment mutations (create / delete / like).
///
/// Mutations update the comment cache (SSOT) first, then call the repository
/// and roll back on failure.
///
/// Copied from [CommentMutation].
@ProviderFor(CommentMutation)
final commentMutationProvider =
    AutoDisposeNotifierProvider<CommentMutation, void>.internal(
      CommentMutation.new,
      name: r'commentMutationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$commentMutationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CommentMutation = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
