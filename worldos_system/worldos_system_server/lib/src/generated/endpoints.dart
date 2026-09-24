/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod/serverpod.dart' as _i1;
import '../auth/email_idp_endpoint.dart' as _i2;
import '../auth/jwt_refresh_endpoint.dart' as _i3;
import '../endpoints/ai_endpoint.dart' as _i4;
import '../endpoints/event_endpoint.dart' as _i5;
import '../endpoints/investigation_endpoint.dart' as _i6;
import '../endpoints/watch_zone_endpoint.dart' as _i7;
import '../greetings/greeting_endpoint.dart' as _i8;
import 'package:worldos_system_server/src/generated/world_event.dart' as _i9;
import 'package:worldos_system_server/src/generated/investigation.dart' as _i10;
import 'package:worldos_system_server/src/generated/watch_zone.dart' as _i11;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i12;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i13;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'emailIdp': _i2.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _i3.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'ai': _i4.AiEndpoint()
        ..initialize(
          server,
          'ai',
          null,
        ),
      'event': _i5.EventEndpoint()
        ..initialize(
          server,
          'event',
          null,
        ),
      'investigation': _i6.InvestigationEndpoint()
        ..initialize(
          server,
          'investigation',
          null,
        ),
      'watchZone': _i7.WatchZoneEndpoint()
        ..initialize(
          server,
          'watchZone',
          null,
        ),
      'greeting': _i8.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i3.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['ai'] = _i1.EndpointConnector(
      name: 'ai',
      endpoint: endpoints['ai']!,
      methodConnectors: {
        'generateBriefing': _i1.MethodConnector(
          name: 'generateBriefing',
          params: {
            'lat': _i1.ParameterDescription(
              name: 'lat',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'lon': _i1.ParameterDescription(
              name: 'lon',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'radiusKm': _i1.ParameterDescription(
              name: 'radiusKm',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'regionName': _i1.ParameterDescription(
              name: 'regionName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _i4.AiEndpoint).generateBriefing(
                session,
                params['lat'],
                params['lon'],
                params['radiusKm'],
                params['regionName'],
              ),
        ),
        'askWorldOS': _i1.MethodConnector(
          name: 'askWorldOS',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _i4.AiEndpoint).askWorldOS(
                session,
                params['query'],
              ),
        ),
      },
    );
    connectors['event'] = _i1.EndpointConnector(
      name: 'event',
      endpoint: endpoints['event']!,
      methodConnectors: {
        'getActiveEvents': _i1.MethodConnector(
          name: 'getActiveEvents',
          params: {
            'typeFilter': _i1.ParameterDescription(
              name: 'typeFilter',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'searchQuery': _i1.ParameterDescription(
              name: 'searchQuery',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['event'] as _i5.EventEndpoint).getActiveEvents(
                    session,
                    params['typeFilter'],
                    params['searchQuery'],
                    params['limit'],
                  ),
        ),
        'getEventsNearLocation': _i1.MethodConnector(
          name: 'getEventsNearLocation',
          params: {
            'lat': _i1.ParameterDescription(
              name: 'lat',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'lon': _i1.ParameterDescription(
              name: 'lon',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'radiusKm': _i1.ParameterDescription(
              name: 'radiusKm',
              type: _i1.getType<double>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['event'] as _i5.EventEndpoint)
                  .getEventsNearLocation(
                    session,
                    params['lat'],
                    params['lon'],
                    params['radiusKm'],
                  ),
        ),
        'saveAndBroadcastEvent': _i1.MethodConnector(
          name: 'saveAndBroadcastEvent',
          params: {
            'event': _i1.ParameterDescription(
              name: 'event',
              type: _i1.getType<_i9.WorldEvent>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['event'] as _i5.EventEndpoint)
                  .saveAndBroadcastEvent(
                    session,
                    params['event'],
                  ),
        ),
      },
    );
    connectors['investigation'] = _i1.EndpointConnector(
      name: 'investigation',
      endpoint: endpoints['investigation']!,
      methodConnectors: {
        'createInvestigation': _i1.MethodConnector(
          name: 'createInvestigation',
          params: {
            'investigation': _i1.ParameterDescription(
              name: 'investigation',
              type: _i1.getType<_i10.Investigation>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['investigation'] as _i6.InvestigationEndpoint)
                      .createInvestigation(
                        session,
                        params['investigation'],
                      ),
        ),
        'getInvestigations': _i1.MethodConnector(
          name: 'getInvestigations',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['investigation'] as _i6.InvestigationEndpoint)
                      .getInvestigations(session),
        ),
      },
    );
    connectors['watchZone'] = _i1.EndpointConnector(
      name: 'watchZone',
      endpoint: endpoints['watchZone']!,
      methodConnectors: {
        'createWatchZone': _i1.MethodConnector(
          name: 'createWatchZone',
          params: {
            'watchZone': _i1.ParameterDescription(
              name: 'watchZone',
              type: _i1.getType<_i11.WatchZone>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['watchZone'] as _i7.WatchZoneEndpoint)
                  .createWatchZone(
                    session,
                    params['watchZone'],
                  ),
        ),
        'getWatchZones': _i1.MethodConnector(
          name: 'getWatchZones',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['watchZone'] as _i7.WatchZoneEndpoint)
                  .getWatchZones(session),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i8.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i12.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i13.Endpoints()
      ..initializeEndpoints(server);
  }
}
