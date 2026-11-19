import 'package:flutter/widgets.dart';

import '../../../../main.dart' show ApiClientScope;
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../../account/data/repositories/account_repository_impl.dart';
import '../../domain/entities/moment.dart';

class MomentPermissionUtils {
  static Future<Map<String, dynamic>> resolve({
    required BuildContext context,
    required Moment moment,
  }) async {
    try {
      final client = ApiClientScope.of(context);
      final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
      final profile = await repo.getProfile();

      bool isOwner = false;
      if (moment.creatorId != null && moment.creatorId!.isNotEmpty && profile.id.isNotEmpty) {
        isOwner = (moment.creatorId == profile.id);
      } else if (moment.userName == 'New Moment') {
        isOwner = false;
      } else if (profile.displayName.isNotEmpty && moment.userName.toLowerCase() == profile.displayName.toLowerCase()) {
        isOwner = true;
      } else if (profile.username != null && profile.username!.isNotEmpty) {
        final cleanU = profile.username!.replaceFirst('@', '').toLowerCase();
        final cleanM = moment.userName.replaceFirst('@', '').toLowerCase();
        if (cleanU == cleanM) {
          isOwner = true;
        }
      } else if (moment.userName == 'You') {
        isOwner = true;
      }

      String displayName = moment.userName;
      if (isOwner) {
        if (profile.displayName.isNotEmpty) {
          displayName = profile.displayName;
        } else if (profile.effectiveUsername.isNotEmpty) {
          displayName = profile.effectiveUsername;
        } else if (profile.username != null && profile.username!.isNotEmpty) {
          displayName = profile.username!;
        } else {
          displayName = 'You';
        }
      } else {
        if (displayName == 'You' || displayName == 'New Moment' || displayName.isEmpty) {
          displayName = 'User';
        }
      }

      return {
        'isOwner': isOwner,
        'displayName': displayName,
      };
    } catch (_) {
      return {
        'isOwner': moment.userName == 'You' || moment.userName.isEmpty,
        'displayName': moment.userName.isEmpty ? 'You' : moment.userName,
      };
    }
  }
}
