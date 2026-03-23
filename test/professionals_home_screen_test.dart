import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfessionalProfileData - Empty state detection', () {
    test('should detect empty expertise', () {
      final data = ProfessionalProfileData();
      final expertise = data.about?.expertise ?? [];
      expect(expertise.isEmpty, true);
    });

    test('should detect non-empty expertise', () {
      final data = ProfessionalProfileData.fromJson({
        'about': {
          'expertise': ['Flutter, Dart', 'Firebase'],
          'totalExperience': {'years': 5, 'months': 0},
        }
      });
      final expertise = data.about?.expertise ?? [];
      expect(expertise.isNotEmpty, true);
      // Test comma splitting (used in UI)
      final cleaned = expertise
          .expand((item) => item.split(','))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      expect(cleaned.length, 3);
      expect(cleaned, ['Flutter', 'Dart', 'Firebase']);
    });

    test('should detect empty services offered', () {
      final data = ProfessionalProfileData();
      final services = data.servicesOffered ?? [];
      expect(services.isEmpty, true);
    });

    test('should detect non-empty services offered', () {
      final data = ProfessionalProfileData.fromJson({
        'servicesOffered': ['Tax Filing', 'GST Registration'],
      });
      final services = data.servicesOffered ?? [];
      expect(services.length, 2);
    });

    test('should detect empty portfolio', () {
      final data = ProfessionalProfileData();
      final portfolio = data.portfolio ?? [];
      expect(portfolio.isEmpty, true);
    });

    test('should detect non-empty portfolio', () {
      final data = ProfessionalProfileData.fromJson({
        'portfolio': [
          {
            'projectTitle': 'E-commerce App',
            'category': 'Mobile App',
            'description': 'Built a full app',
          }
        ],
      });
      final portfolio = data.portfolio ?? [];
      expect(portfolio.length, 1);
      expect(portfolio.first.projectTitle, 'E-commerce App');
    });

    test('should detect empty certificates', () {
      final data = ProfessionalProfileData();
      final certs = data.certificates ?? [];
      expect(certs.isEmpty, true);
    });

    test('should detect empty gallery', () {
      final data = ProfessionalProfileData();
      final urls = data.gallery?.signedUrls ?? [];
      expect(urls.isEmpty, true);
    });

    test('should detect empty contact', () {
      final data = ProfessionalProfileData();
      final contact = data.contact;
      final hasContact = contact != null &&
          ((contact.website ?? '').isNotEmpty ||
              (contact.phone ?? '').isNotEmpty ||
              (contact.email ?? '').isNotEmpty);
      expect(hasContact, false);
    });

    test('should detect existing contact', () {
      final data = ProfessionalProfileData.fromJson({
        'contact': {
          'website': 'https://example.com',
          'phone': '9876543210',
          'email': 'test@example.com',
          'address': 'Delhi',
        }
      });
      final contact = data.contact;
      final hasContact = contact != null &&
          ((contact.website ?? '').isNotEmpty ||
              (contact.phone ?? '').isNotEmpty ||
              (contact.email ?? '').isNotEmpty);
      expect(hasContact, true);
    });

    test('should detect empty timings', () {
      final data = ProfessionalProfileData();
      final hasTimings = data.timings?.schedule != null;
      expect(hasTimings, false);
    });
  });

  group('ProfessionalProfileResModel - JSON parsing', () {
    test('should parse full profile from JSON', () {
      final json = {
        'success': true,
        'data': {
          '_id': 'test123',
          'userId': 'user456',
          'basicDetails': {
            'fullName': 'John Doe',
            'professionalTitle': 'Tax Consultant',
            'shortTagline': 'Expert in tax filing',
          },
          'about': {
            'expertise': ['Tax, GST'],
            'totalExperience': {'years': 10, 'months': 5},
            'description': 'Experienced consultant',
          },
          'servicesOffered': ['Tax Filing', 'Audit'],
          'portfolio': [
            {
              'projectTitle': 'Project A',
              'category': 'Consulting',
            }
          ],
          'certificates': [
            {
              'title': 'CA Certificate',
              'description': 'Chartered Accountant',
            }
          ],
        },
      };

      final model = ProfessionalProfileResModel.fromJson(json);
      expect(model.success, true);
      expect(model.data, isNotNull);
      expect(model.data!.basicDetails?.fullName, 'John Doe');
      expect(model.data!.about?.expertise?.length, 1);
      expect(model.data!.servicesOffered?.length, 2);
      expect(model.data!.portfolio?.length, 1);
      expect(model.data!.certificates?.length, 1);
    });

    test('should handle null data gracefully', () {
      final json = {'success': true, 'data': null};
      final model = ProfessionalProfileResModel.fromJson(json);
      expect(model.success, true);
      expect(model.data, isNull);
    });

    test('should handle empty data object', () {
      final json = {'success': true, 'data': {}};
      final model = ProfessionalProfileResModel.fromJson(json);
      expect(model.data, isNotNull);
      expect(model.data!.basicDetails, isNull);
      expect(model.data!.about, isNull);
      expect(model.data!.portfolio, isNull);
      expect(model.data!.certificates, isNull);
      expect(model.data!.servicesOffered, isNull);
      expect(model.data!.contact, isNull);
      expect(model.data!.timings, isNull);
      expect(model.data!.gallery, isNull);
    });
  });

  group('ProfessionalProfileData - Section data checks', () {
    late ProfessionalProfileData fullData;

    setUp(() {
      fullData = ProfessionalProfileData.fromJson({
        'basicDetails': {
          'fullName': 'Test User',
          'professionalTitle': 'Developer',
        },
        'about': {
          'expertise': ['Flutter', 'React'],
          'totalExperience': {'years': 5, 'months': 3},
          'description': 'Full stack developer',
        },
        'servicesOffered': ['App Dev', 'Web Dev', 'Consulting'],
        'portfolio': [
          {'projectTitle': 'App A', 'category': 'Mobile'},
          {'projectTitle': 'Web B', 'category': 'Web'},
        ],
        'certificates': [
          {'title': 'AWS Cert', 'fileUrl': 'https://img.com/cert.jpg'},
        ],
        'contact': {
          'website': 'https://dev.com',
          'phone': '1234567890',
          'email': 'dev@test.com',
          'address': 'Bangalore',
          'location': {
            'type': 'Point',
            'coordinates': [12.97, 77.59],
          },
        },
      });
    });

    test('basicDetails should parse correctly', () {
      expect(fullData.basicDetails?.fullName, 'Test User');
      expect(fullData.basicDetails?.professionalTitle, 'Developer');
    });

    test('about section should parse expertise as list', () {
      expect(fullData.about?.expertise, isA<List>());
      expect(fullData.about?.expertise?.length, 2);
    });

    test('about total experience should parse', () {
      expect(fullData.about?.totalExperience?.years, 5);
      expect(fullData.about?.totalExperience?.months, 3);
    });

    test('services offered should be list of strings', () {
      expect(fullData.servicesOffered, isA<List<String>>());
      expect(fullData.servicesOffered?.length, 3);
    });

    test('portfolio should parse multiple items', () {
      expect(fullData.portfolio?.length, 2);
      expect(fullData.portfolio?.first.projectTitle, 'App A');
    });

    test('certificates should parse with fileUrl', () {
      expect(fullData.certificates?.length, 1);
      expect(fullData.certificates?.first.title, 'AWS Cert');
    });

    test('contact location coordinates should parse', () {
      expect(fullData.contact?.location?.coordinates?.length, 2);
      expect(fullData.contact?.location?.coordinates?[0], 12.97);
      expect(fullData.contact?.location?.coordinates?[1], 77.59);
    });
  });
}
