class DepartmentModel {
  final int id;
  final String name;
  final String description;
  final String isActive;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? 'N',
    );
  }
}

class GroupModel {
  final int id;
  final String name;
  final String? description;
  final String isActive;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? 'N',
    );
  }
}

class CompanyModel {
  final int id;
  final String name;
  final String website;
  final String email;
  final String phone;
  final String address;
  final String cityZipcode;
  final String countryState;
  final String typeOfWork;
  final int noOfEmployees;
  final String? logoUrl;
  final String expiryDate;
  final String isActive;

  CompanyModel({
    required this.id,
    required this.name,
    required this.website,
    required this.email,
    required this.phone,
    required this.address,
    required this.cityZipcode,
    required this.countryState,
    required this.typeOfWork,
    required this.noOfEmployees,
    this.logoUrl,
    required this.expiryDate,
    required this.isActive,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      website: json['website'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      cityZipcode: json['city_zipcode'] ?? '',
      countryState: json['country_state'] ?? '',
      typeOfWork: json['type_of_work'] ?? '',
      noOfEmployees: json['no_of_employees'] ?? 0,
      logoUrl: json['logo_url'],
      expiryDate: json['expiry_date'] ?? '',
      isActive: json['is_active'] ?? 'N',
    );
  }
}

class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String mobileNo;
  final String? officePhone;     // Nullable - was causing crash
  final String? employeeId;      // Nullable
  final int roleId;
  final String roleName;
  final int departmentId;
  final DepartmentModel? department;   // Nullable (safe)
  final int? groupId;                  // Nullable
  final GroupModel? group;             // Nullable
  final int companyId;
  final CompanyModel? company;         // Nullable (safe)
  final bool twoFactorEnabled;
  final String lastLoginAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobileNo,
    this.officePhone,
    this.employeeId,
    required this.roleId,
    required this.roleName,
    required this.departmentId,
    this.department,
    this.groupId,
    this.group,
    required this.companyId,
    this.company,
    required this.twoFactorEnabled,
    required this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      officePhone: json['office_phone'] as String?,
      employeeId: json['employee_id'] as String?,
      roleId: json['role_id'] ?? 0,
      roleName: json['role_name'] ?? '',
      departmentId: json['department_id'] ?? 0,
      department: json['department'] != null
          ? DepartmentModel.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      groupId: json['group_id'] as int?,
      group: json['group'] != null
          ? GroupModel.fromJson(json['group'] as Map<String, dynamic>)
          : null,
      companyId: json['company_id'] ?? 0,
      company: json['company'] != null
          ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      lastLoginAt: json['last_login_at'] ?? '',
    );
  }
}