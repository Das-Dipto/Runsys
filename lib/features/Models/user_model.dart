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
      id: json['id'],
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
      id: json['id'],
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
      id: json['id'],
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
  final String officePhone;
  final String employeeId;
  final int roleId;
  final String roleName;
  final int departmentId;
  final DepartmentModel department;
  final int groupId;
  final GroupModel group;
  final int companyId;
  final CompanyModel company;
  final bool twoFactorEnabled;
  final String lastLoginAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobileNo,
    required this.officePhone,
    required this.employeeId,
    required this.roleId,
    required this.roleName,
    required this.departmentId,
    required this.department,
    required this.groupId,
    required this.group,
    required this.companyId,
    required this.company,
    required this.twoFactorEnabled,
    required this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      officePhone: json['office_phone'] ?? '',
      employeeId: json['employee_id'] ?? '',
      roleId: json['role_id'],
      roleName: json['role_name'] ?? '',
      departmentId: json['department_id'],
      department: DepartmentModel.fromJson(json['department']),
      groupId: json['group_id'],
      group: GroupModel.fromJson(json['group']),
      companyId: json['company_id'],
      company: CompanyModel.fromJson(json['company']),
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      lastLoginAt: json['last_login_at'] ?? '',
    );
  }
}