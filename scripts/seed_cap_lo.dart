// Live CAP seed for LO Committee module.
//
// Usage:
//   dart run scripts/seed_cap_lo.dart --email=nodal@example.com
//
// Optional:
//   --base-url=http://35.244.48.209:8080
//   --org-email=org.seed@example.com
//   --lo-email=lo.seed@example.com
//   --do-pdf=path/to/template.pdf
//   --token=<JWT>   (skip OTP when you already have a Nodal token)
//
// Prerequisites: CAP Users must already exist for Nodal / Org Rep / LO emails.
// See docs/lo-committee-requirements-matrix.md for the full runbook.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

const _defaultBaseUrl = 'http://35.244.48.209:8080';
const _seedOrgTypeName = 'DPSU';
const _seedOrgName = 'Seed BEL';
const _seedActivityTitle = 'Airport Reception';
const _seedDoTemplateName = 'Standard LO Nomination DO';

Future<void> main(List<String> args) async {
  final opts = _Args.parse(args);
  if (opts.email == null || opts.email!.isEmpty) {
    stderr.writeln(
      'Usage: dart run scripts/seed_cap_lo.dart --email=<nodal-cap-email>\n'
      'Optional: --base-url= --org-email= --lo-email= --do-pdf= --token=',
    );
    exit(64);
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: opts.baseUrl,
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  stdout.writeln('CAP seed → ${opts.baseUrl}');
  stdout.writeln('Nodal email: ${opts.email}');

  final token = opts.token ?? await _authenticate(dio, opts.email!);
  dio.options.headers['Authorization'] = 'Bearer $token';
  stdout.writeln('Authenticated.\n');

  final orgTypeId = await _ensureOrgType(dio);
  await _ensureEmailTemplates(dio);
  await _ensureDoTemplate(dio, orgTypeId, opts.doPdfPath);
  final activityId = await _ensureActivity(dio);
  final orgId = await _ensureOrganisation(dio, orgTypeId, opts.orgEmail);
  final lo = await _ensureLiaisonOfficer(dio, orgId, opts.loEmail);
  final assignment = await _ensureAssignment(dio, lo);
  await _ensureTask(dio, lo: lo, assignment: assignment, activityId: activityId);

  _printMobileTestCard(opts);
}

Future<String> _authenticate(Dio dio, String email) async {
  await dio.post('/api/auth/check-email', data: {'email': email});

  final captchaRes = await dio.get('/api/auth/captcha');
  final captchaData = _dataMap(captchaRes.data);
  final captchaId = captchaData['captchaId']?.toString() ?? '';
  final imageB64 = captchaData['imageBase64']?.toString() ?? '';
  if (captchaId.isEmpty) {
    throw StateError('CAPTCHA response missing captchaId.');
  }

  final captchaPath = await _writeCaptchaImage(imageB64);
  stdout.writeln('CAPTCHA saved to: $captchaPath');
  _tryOpen(captchaPath);
  final captchaAnswer = _prompt('Enter CAPTCHA answer: ');
  if (captchaAnswer.isEmpty) {
    throw StateError('CAPTCHA answer required.');
  }

  final otpReq = await dio.post(
    '/api/auth/request-otp',
    data: {
      'email': email,
      'captchaId': captchaId,
      'captchaAnswer': captchaAnswer,
    },
  );
  if (!_ok(otpReq)) {
    throw StateError('request-otp failed: ${_msg(otpReq.data)}');
  }
  stdout.writeln(_msg(otpReq.data) ?? 'OTP sent. Check the Nodal inbox.');

  final otp = _prompt('Enter OTP: ');
  if (otp.isEmpty) {
    throw StateError('OTP required.');
  }

  final verify = await dio.post(
    '/api/auth/verify-otp',
    data: {'email': email, 'otp': otp},
  );
  if (!_ok(verify)) {
    throw StateError('verify-otp failed: ${_msg(verify.data)}');
  }
  final jwt = _dataMap(verify.data);
  final token = jwt['accessToken']?.toString() ?? '';
  final role = jwt['role']?.toString() ?? '';
  if (token.isEmpty) {
    throw StateError('verify-otp returned empty accessToken.');
  }
  stdout.writeln('Role: $role');
  return token;
}

Future<String> _ensureOrgType(Dio dio) async {
  final list = await _listMaps(dio, '/app/lo-org-types');
  for (final e in list) {
    if ((e['displayName']?.toString() ?? '') == _seedOrgTypeName) {
      stdout.writeln('Org type exists: $_seedOrgTypeName (${e['id']})');
      return e['id'].toString();
    }
  }
  final res = await dio.post(
    '/app/lo-org-types',
    data: {
      'displayName': _seedOrgTypeName,
      'description': 'Defence PSU (seed)',
      'isActive': true,
    },
  );
  final created = _requireData(res, 'create org type');
  stdout.writeln('Created org type: $_seedOrgTypeName (${created['id']})');
  return created['id'].toString();
}

Future<void> _ensureEmailTemplates(Dio dio) async {
  final wanted = <Map<String, String>>[
    {
      'name': 'Seed DO Letter Communication',
      'purposeTag': 'DO Letter Communication',
      'subject': 'Request to nominate Liaison Officers — Aero India 2027',
      'body':
          'Dear Sir/Madam,\n\nPlease nominate Liaison Officers for Aero India 2027. '
              'The signed DO letter is attached.\n\nRegards,\nLO Committee',
    },
    {
      'name': 'Seed Profile Completion Reminder',
      'purposeTag': 'Profile Completion Reminder',
      'subject': 'Reminder: Complete your LO profile',
      'body':
          'Dear Liaison Officer,\n\nPlease log in and complete your profile.\n\nRegards,\nLO Committee',
    },
    {
      'name': 'Seed Assignment Notification',
      'purposeTag': 'Assignment Notification',
      'subject': 'You have been assigned a delegate',
      'body':
          'Dear Liaison Officer,\n\nYou have a new delegate assignment. '
              'Please review details in the portal.\n\nRegards,\nLO Committee',
    },
  ];

  final existing = await _listMaps(dio, '/app/email-templates');
  final names = existing.map((e) => e['name']?.toString() ?? '').toSet();

  for (final t in wanted) {
    if (names.contains(t['name'])) {
      stdout.writeln('Email template exists: ${t['name']}');
      continue;
    }
    final res = await dio.post(
      '/app/email-templates',
      data: {
        'name': t['name'],
        'purposeTag': t['purposeTag'],
        'subject': t['subject'],
        'body': t['body'],
        'isActive': true,
      },
    );
    _requireData(res, 'create email template ${t['name']}');
    stdout.writeln('Created email template: ${t['name']}');
  }
}

Future<void> _ensureDoTemplate(
  Dio dio,
  String orgTypeId,
  String? doPdfPath,
) async {
  final list = await _listMaps(dio, '/app/do-letter-templates');
  for (final e in list) {
    if ((e['templateName']?.toString() ?? '') == _seedDoTemplateName) {
      stdout.writeln('DO template exists: $_seedDoTemplateName (${e['id']})');
      return;
    }
  }

  final payload = {
    'templateName': _seedDoTemplateName,
    'signingAuthority': 'Chairman, LO Committee',
    'applicableOrgTypeIds': [orgTypeId],
    'isActive': true,
  };

  final formMap = <String, dynamic>{
    'payload': jsonEncode(payload),
  };
  if (doPdfPath != null && doPdfPath.isNotEmpty) {
    final file = File(doPdfPath);
    if (!file.existsSync()) {
      throw StateError('DO PDF not found: $doPdfPath');
    }
    formMap['file'] = await MultipartFile.fromFile(
      file.path,
      filename: file.uri.pathSegments.last,
    );
  }

  final res = await dio.post(
    '/app/do-letter-templates',
    data: FormData.fromMap(formMap),
  );
  final created = _requireData(res, 'create DO template');
  stdout.writeln(
    'Created DO template: $_seedDoTemplateName (${created['id']})'
    '${doPdfPath == null ? ' (metadata only — no PDF)' : ''}',
  );
}

Future<String> _ensureActivity(Dio dio) async {
  final list = await _listMaps(dio, '/app/lo-activities');
  for (final e in list) {
    if ((e['activityTitle']?.toString() ?? '') == _seedActivityTitle) {
      stdout.writeln('Activity exists: $_seedActivityTitle (${e['id']})');
      return e['id'].toString();
    }
  }
  final res = await dio.post(
    '/app/lo-activities',
    data: {
      'activityTitle': _seedActivityTitle,
      'activityDesc': 'Receive VIP at airport (seed)',
      'isActive': true,
    },
  );
  final created = _requireData(res, 'create activity');
  stdout.writeln('Created activity: $_seedActivityTitle (${created['id']})');
  return created['id'].toString();
}

Future<String> _ensureOrganisation(
  Dio dio,
  String orgTypeId,
  String orgEmail,
) async {
  final list = await _listMaps(dio, '/app/lo-organisations');
  for (final e in list) {
    if ((e['orgName']?.toString() ?? '') == _seedOrgName) {
      stdout.writeln('Organisation exists: $_seedOrgName (${e['id']})');
      return e['id'].toString();
    }
  }
  final res = await dio.post(
    '/app/lo-organisations',
    data: {
      'orgName': _seedOrgName,
      'orgTypeId': orgTypeId,
      'headName': 'Seed Head',
      'headDesignation': 'CMD',
      'address': 'Bengaluru',
      'primaryEmail': orgEmail,
      'primaryContact': '+919999999991',
      'remarks': 'Created by seed_cap_lo.dart',
    },
  );
  final created = _requireData(res, 'create organisation');
  stdout.writeln('Created organisation: $_seedOrgName (${created['id']})');
  return created['id'].toString();
}

Future<Map<String, dynamic>> _ensureLiaisonOfficer(
  Dio dio,
  String orgId,
  String loEmail,
) async {
  final list = await _listMaps(dio, '/app/liaison-officers');
  for (final e in list) {
    final email = (e['officialEmail'] ?? e['primaryEmail'] ?? '').toString();
    if (email.toLowerCase() == loEmail.toLowerCase()) {
      stdout.writeln('LO exists: $loEmail (${e['id']})');
      return e;
    }
  }
  final res = await dio.post(
    '/app/liaison-officers',
    data: {
      'orgId': orgId,
      'salutation': 'Mr',
      'firstName': 'Seed',
      'lastName': 'Liaison',
      'primaryEmail': loEmail,
      'primaryMobile': '+919999999992',
      'rank': 'Wing Commander',
      'designation': 'Liaison Officer',
    },
  );
  final created = _requireData(res, 'create liaison officer');
  stdout.writeln('Created LO: $loEmail (${created['id']})');
  return created;
}

Future<Map<String, dynamic>?> _ensureAssignment(
  Dio dio,
  Map<String, dynamic> lo,
) async {
  final loId = lo['id']?.toString();
  if (loId == null || loId.isEmpty) {
    stdout.writeln('SKIP assignment: LO id missing.');
    return null;
  }

  final existing = await _listMaps(dio, '/app/lo-assignments');
  for (final a in existing) {
    if (a['loId']?.toString() == loId) {
      stdout.writeln('Assignment exists for LO $loId (${a['id']})');
      return a;
    }
  }

  final delegates = await _listMaps(dio, '/app/lo-assignments/delegates');
  if (delegates.isEmpty) {
    stdout.writeln(
      'SKIP assignment: no Attending delegates in CAP.\n'
      '  Create an RSVP-Attending delegate in CAP Admin, then re-run this script.',
    );
    return null;
  }

  final delegate = delegates.first;
  final personId = delegate['personId']?.toString();
  if (personId == null || personId.isEmpty) {
    stdout.writeln('SKIP assignment: first delegate missing personId.');
    return null;
  }

  // OpenAPI: query params loId + personId. Also send body fields used by the app.
  final res = await dio.post(
    '/app/lo-assignments',
    queryParameters: {'loId': loId, 'personId': personId},
    data: {
      'loId': loId,
      'personId': personId,
      'attendeeId': delegate['attendeeId'],
      'delegateType':
          delegate['attendeeType'] ?? delegate['delegateType'],
      'delegateName': delegate['fullName'],
    },
  );
  if (!_ok(res)) {
    stdout.writeln('SKIP assignment: ${_msg(res.data)}');
    return null;
  }
  final created = _dataMap(res.data);
  stdout.writeln(
    'Created assignment: LO → ${delegate['fullName']} (${created['id']})',
  );
  return created;
}

Future<void> _ensureTask(
  Dio dio, {
  required Map<String, dynamic> lo,
  required Map<String, dynamic>? assignment,
  required String activityId,
}) async {
  if (assignment == null) {
    stdout.writeln('SKIP task: no assignment.');
    return;
  }
  final loId = lo['id']?.toString();
  final assignId = assignment['id']?.toString();
  if (loId == null || assignId == null) {
    stdout.writeln('SKIP task: missing loId/loAssignId.');
    return;
  }

  final tasks = await _listMaps(dio, '/app/lo-tasks');
  for (final t in tasks) {
    if (t['loAssignId']?.toString() == assignId &&
        (t['taskTitle']?.toString() ?? '') == _seedActivityTitle) {
      stdout.writeln('Task exists: $_seedActivityTitle (${t['id']})');
      return;
    }
  }

  final res = await dio.post(
    '/app/lo-tasks',
    data: {
      'loId': loId,
      'loAssignId': assignId,
      'delegatePersonId': assignment['personId'],
      'delegateName': assignment['delegateName'],
      'taskSource': 'ACTIVITY_MASTER',
      'activityId': activityId,
      'taskTitle': _seedActivityTitle,
      'taskDescription': 'Receive VIP at airport (seed)',
      'locationVenue': 'Kempegowda International Airport',
      'remarks': 'Created by seed_cap_lo.dart',
    },
  );
  if (!_ok(res)) {
    stdout.writeln('SKIP task: ${_msg(res.data)}');
    return;
  }
  final created = _dataMap(res.data);
  stdout.writeln('Created task: $_seedActivityTitle (${created['id']})');
}

void _printMobileTestCard(_Args opts) {
  stdout.writeln('''

════════════════════════════════════════════════════════════
 MOBILE TEST CARD — Aero India LO App vs live CAP
════════════════════════════════════════════════════════════
 Base URL : ${opts.baseUrl}

 flutter run \\
   --dart-define=USE_MOCK_API=false \\
   --dart-define=API_BASE_URL=${opts.baseUrl}

 Logins (OTP from CAP email — not 123456 on live):
   Nodal   : ${opts.email}
   Org Rep : ${opts.orgEmail}  (must be a CAP User)
   LO      : ${opts.loEmail}   (must be a CAP User)

 Seeded entities (idempotent):
   Org type      : $_seedOrgTypeName
   Organisation  : $_seedOrgName
   Activity      : $_seedActivityTitle
   Email templates + DO template metadata

 Mock mode (offline): USE_MOCK_API=true · OTP 123456
   liaison@test.com / org@test.com / admin@aeroindia.gov.in

 Docs: docs/lo-committee-requirements-matrix.md
════════════════════════════════════════════════════════════
''');
}

// ── helpers ─────────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> _listMaps(Dio dio, String path) async {
  final res = await dio.get(path);
  if (!_ok(res)) {
    throw StateError('GET $path failed: ${_msg(res.data)}');
  }
  final raw = res.data;
  if (raw is Map && raw['data'] is List) {
    return (raw['data'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

Map<String, dynamic> _requireData(Response res, String label) {
  if (!_ok(res)) {
    throw StateError('$label failed: ${_msg(res.data)}');
  }
  return _dataMap(res.data);
}

Map<String, dynamic> _dataMap(dynamic body) {
  if (body is Map && body['data'] is Map) {
    return Map<String, dynamic>.from(body['data'] as Map);
  }
  if (body is Map<String, dynamic>) return body;
  if (body is Map) return Map<String, dynamic>.from(body);
  return {};
}

bool _ok(Response res) {
  final code = res.statusCode ?? 0;
  if (code >= 400) return false;
  final body = res.data;
  if (body is Map && body['success'] == false) return false;
  return true;
}

String? _msg(dynamic body) {
  if (body is Map) return body['message']?.toString();
  return body?.toString();
}

String _prompt(String label) {
  stdout.write(label);
  return stdin.readLineSync()?.trim() ?? '';
}

Future<String> _writeCaptchaImage(String imageBase64) async {
  final raw = imageBase64.contains(',')
      ? imageBase64.split(',').last
      : imageBase64;
  final bytes = base64Decode(raw);
  final dir = Directory.systemTemp;
  final file = File('${dir.path}${Platform.pathSeparator}cap_captcha.png');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

void _tryOpen(String path) {
  try {
    if (Platform.isWindows) {
      Process.start('cmd', ['/c', 'start', '', path], runInShell: true);
    } else if (Platform.isMacOS) {
      Process.start('open', [path]);
    } else if (Platform.isLinux) {
      Process.start('xdg-open', [path]);
    }
  } catch (_) {
    // User can open the file manually.
  }
}

class _Args {
  _Args({
    required this.baseUrl,
    required this.email,
    required this.orgEmail,
    required this.loEmail,
    required this.doPdfPath,
    required this.token,
  });

  final String baseUrl;
  final String? email;
  final String orgEmail;
  final String loEmail;
  final String? doPdfPath;
  final String? token;

  factory _Args.parse(List<String> args) {
    String baseUrl = _defaultBaseUrl;
    String? email;
    String orgEmail = 'org.seed@example.com';
    String loEmail = 'lo.seed@example.com';
    String? doPdf;
    String? token;

    for (final a in args) {
      if (a.startsWith('--base-url=')) {
        baseUrl = a.substring('--base-url='.length).trim();
      } else if (a.startsWith('--email=')) {
        email = a.substring('--email='.length).trim();
      } else if (a.startsWith('--org-email=')) {
        orgEmail = a.substring('--org-email='.length).trim();
      } else if (a.startsWith('--lo-email=')) {
        loEmail = a.substring('--lo-email='.length).trim();
      } else if (a.startsWith('--do-pdf=')) {
        doPdf = a.substring('--do-pdf='.length).trim();
      } else if (a.startsWith('--token=')) {
        token = a.substring('--token='.length).trim();
      }
    }

    return _Args(
      baseUrl: baseUrl.replaceAll(RegExp(r'/$'), ''),
      email: email,
      orgEmail: orgEmail,
      loEmail: loEmail,
      doPdfPath: doPdf,
      token: token,
    );
  }
}
