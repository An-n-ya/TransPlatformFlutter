// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_interaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postInteractionHash() => r'7563a89d4d1db87ab6ef4f130a9924c9fdb524f6';

/// Optimistic post mutations (like / collect / delete).
///
/// Every mutation updates the cache (SSOT) first so the UI reacts instantly,
/// then calls the repository and rolls back on failure.
///
/// Copied from [PostInteraction].
@ProviderFor(PostInteraction)
final postInteractionProvider =
    AutoDisposeNotifierProvider<PostInteraction, void>.internal(
      PostInteraction.new,
      name: r'postInteractionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$postInteractionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PostInteraction = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
