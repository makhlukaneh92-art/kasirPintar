class CustomerModel {
  final int? id;
  final String name;
  final String? phone;

  CustomerModel({
    this.id,
    required this.name,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
    );
  }
}
