class UserAddress {
  String street;
  String subLocality;
  String city;
  String state;
  String country;
  String postalCode;

  UserAddress({
    this.street = '',
    this.subLocality = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
  });

  // Helper to check if address is empty
  bool get isEmpty => street.isEmpty && city.isEmpty && state.isEmpty;

  // Helper to get formatted string for UI
  String get formattedAddress {
    return [street, subLocality, city, state, country, postalCode]
        .where((element) => element.isNotEmpty)
        .join(', ');
  }
}