// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_mutation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followRelationsHash() => r'e069ac00db639bd104bee2a17378f02ae1cd58dd';

/// Single Source of Truth for "who the current user follows".
///
/// The followee list is loaded once per session (through [followListProvider]
/// so the user cache is populated too) and held here for instant follow-state
/// lookups anywhere in the app.
///
/// Copied from [FollowRelations].
@ProviderFor(FollowRelations)
final followRelationsProvider =
    NotifierProvider<FollowRelations, FollowRelationsState>.internal(
      FollowRelations.new,
      name: r'followRelationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$followRelationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FollowRelations = Notifier<FollowRelationsState>;
String _$followMutationHash() => r'22b8376c05a56b6499df2b0658779e1a1c4a554f';

/// Optimistic follow / unfollow mutations.
///
/// The follow relationship is updated in [FollowRelations] first so every
/// follow button in the app rebuilds instantly; on failure it rolls back to
/// the pre-mutation snapshot and shows an error.
///
/// Copied from [FollowMutation].
@ProviderFor(FollowMutation)
final followMutationProvider =
    AutoDisposeNotifierProvider<FollowMutation, void>.internal(
      FollowMutation.new,
      name: r'followMutationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$followMutationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FollowMutation = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
