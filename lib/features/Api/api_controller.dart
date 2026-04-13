import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Home/Widgets/sort_bottom_sheet.dart';
import '../Home/Widgets/filter_bottom_sheet.dart';

class ApiController {
  static const String _baseUrl = 'http://159.65.156.164:5000';

  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return {
        'device_id': info.id,
        'device_name': '${info.manufacturer} ${info.model}',
      };
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return {
        'device_id': info.identifierForVendor ?? 'ios_unknown',
        'device_name': info.name,
      };
    }

    return {
      'device_id': 'unknown_device',
      'device_name': 'Unknown Device',
    };
  }

  static Future<Map<String, dynamic>> login(
      String email, String password, String rememberMe) async {

        print("This is api body- ${email}, ${password}, ${rememberMe}");
    try {
      final deviceData = await _getDeviceInfo();
      final url = Uri.parse('$_baseUrl/api/v1/auth/user_login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'rememberMe': rememberMe == "Y" ? true : false,
          'device_id': deviceData['device_id'],
          'device_name': deviceData['device_name'],
        }),
      );

      final data = jsonDecode(response.body);

      print("This is data coming from API- ${data}");

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> getMyTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final url = Uri.parse('$_baseUrl/api/v1/app_task/my-tasks');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      print("This is getMyTasks Data- ${data}");
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch tasks'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please check your connection.'};
    }
  }

  static Future<Map<String, dynamic>> getFilteredTasks({
    String? dateRange,        // "today", "tomorrow", "this_week", "all"
    SortOption? sortOption,   // For status: PENDING, IN_PROGRESS
    FilterOption? filterOption, // For priority: URGENT, HIGH
    int? page,
    int? limit,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final queryParams = <String, String>{};

      // Date Range
      if (dateRange != null && dateRange != "all") {
        queryParams['date_range'] = dateRange;
      }

      // Sort Option → status
      if (sortOption != null) {
        String statusValue = '';
        switch (sortOption) {
          case SortOption.pending:
            statusValue = "PENDING";
            break;
          case SortOption.inProgress:
            statusValue = "IN_PROGRESS";
            break;
        }
        if (statusValue.isNotEmpty) {
          queryParams['status'] = statusValue;
        }
      }

      // Filter Option → priority
      if (filterOption != null) {
        String priorityValue = '';
        switch (filterOption) {
          case FilterOption.high:
            priorityValue = "HIGH";
            break;
          case FilterOption.urgent:
            priorityValue = "URGENT";
            break;
        }
        if (priorityValue.isNotEmpty) {
          queryParams['priority'] = priorityValue;
        }
      }

      final uri = Uri.parse('$_baseUrl/api/v1/app_task/my-tasks')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print("API Call: $uri");

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch tasks'
        };
      }
    } catch (e) {
      print("getFilteredTasks error: $e");
      return {
        'success': false,
        'message': 'Network error. Please check your connection.'
      };
    }
  }
  static Future<Map<String, dynamic>> getTaskDetail(int taskId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$_baseUrl/api/v1/app_task/tasks/$taskId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return {'success': true, 'data': data['data']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Failed to fetch task detail'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error. Please check your connection.'};
  }
}


static Future<Map<String, dynamic>> getProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$_baseUrl/api/v1/app_auth/profile');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return {'success': true, 'data': data['user']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Failed to fetch profile'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error. Please check your connection.'};
  }
}


 static Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {

      print("This is api body for changing password- ${currentPassword}, ${newPassword}");

    try {
      final deviceData = await _getDeviceInfo();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final url = Uri.parse('$_baseUrl/api/v1/app_auth/change-password');

      final response = await http.post(
        url,
         headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "currentPassword": currentPassword.toString(),
          "newPassword": newPassword.toString(),
          "confirmPassword": newPassword.toString()
        }),
      );

      final data = jsonDecode(response.body);

      print("This is data coming from API- ${data}");

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> makeComment(
      int taskId, String comment) async {

      print("This is api body for comment, taskId- ${taskId}");

    try {
      final deviceData = await _getDeviceInfo();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final url = Uri.parse('$_baseUrl/api/v1/app_task/tasks/$taskId/comments');

      final response = await http.post(
        url,
         headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "comment": comment.toString(),
        }),
      );

      final data = jsonDecode(response.body);

      print("This is data coming from API- ${data}");

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> startTimeLog(int taskId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$_baseUrl/api/v1/app_task/time-logs/start');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'task_id': taskId}),
    );

    final data = jsonDecode(response.body);
    print("startTimeLog response- $data  and TaskId- $taskId");

    if (response.statusCode == 200 && data['success'] == true) {
      return {'success': true, 'data': data['data']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Failed to start timer'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error. Please check your connection.'};
  }
}

static Future<Map<String, dynamic>> stopTimeLog(int logId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$_baseUrl/api/v1/app_task/time-logs/$logId/stop');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    print("stopTimeLog response- $data");

    if (response.statusCode == 200 && data['success'] == true) {
      return {'success': true, 'data': data['data']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Failed to stop timer'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error. Please check your connection.'};
  }
}

}