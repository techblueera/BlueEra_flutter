import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts HTTPS URLs, including query strings and fragments', () {
    expect(ValidationMethod.isHttpsUrl('https://beapp.in'), isTrue);
    expect(
        ValidationMethod.isHttpsUrl(
            'https://example.com/path/page?q=a+b&x=1#top'),
        isTrue);
    expect(ValidationMethod.isHttpsUrl("https://example.com/it's"), isTrue);
  });

  test('rejects anything that is not a plain HTTPS URL', () {
    expect(ValidationMethod.isHttpsUrl('http://example.com'), isFalse);
    expect(ValidationMethod.isHttpsUrl('example.com'), isFalse);
    expect(ValidationMethod.isHttpsUrl('https://'), isFalse);
    expect(ValidationMethod.isHttpsUrl('https://exa mple.com'), isFalse);
  });
}
