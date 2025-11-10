import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'flutter_openim_sdk_ffi_bindings_generated.dart';
import 'src/utils.dart';

// Message Edit Feature
export 'src/message_edit_service.dart';
export 'src/widgets/message_edit_widget.dart';

/// callback
part 'src/callback/_error.dart';
part 'src/callback/_listen.dart';
part 'src/callback/_listen_to_class.dart';
part 'src/callback/_method.dart';
part 'src/callback/_success.dart';

/// enum
part 'src/enum/_port_method.dart';
part 'src/enum/conversation_type.dart';
part 'src/enum/group_at_type.dart';
part 'src/enum/group_role_level.dart';
part 'src/enum/group_type.dart';
part 'src/enum/group_verification.dart';
part 'src/enum/im_platform.dart';
part 'src/enum/listener_type.dart';
part 'src/enum/message_status.dart';
part 'src/enum/message_type.dart';
part 'src/enum/sdk_error_code.dart';

/// manager
part 'src/manager/im_conversation_manager.dart';
part 'src/manager/im_friendship_manager.dart';
part 'src/manager/im_group_manager.dart';
part 'src/manager/im_manager.dart';
part 'src/manager/im_message_manager.dart';
part 'src/manager/im_user_manager.dart';
part 'src/models/applicant_req.dart';

/// models
part 'src/models/conversation_info.dart';
part 'src/models/group_info.dart';
part 'src/models/input_status_changed_data.dart';
part 'src/models/message.dart';
part 'src/models/notification_info.dart';
part 'src/models/openim.dart';
part 'src/models/search_info.dart';
part 'src/models/set_group_member_info.dart';
part 'src/models/update_req.dart';
part 'src/models/user_info.dart';
part 'src/models/user_info_full.dart';
part 'src/models/edit_models.dart';

/// root
part 'src/openim.dart';
part 'src/openim_error.dart';
part 'src/openim_listener.dart';
part 'src/openim_manager.dart';
