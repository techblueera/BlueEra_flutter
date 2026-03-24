import 'package:BlueEra/features/common/qr_code/model/qr_design_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrDesignModel', () {
    test('designs list should not be empty', () {
      final designs = QrDesignModel.designs;
      expect(designs.isNotEmpty, true);
    });

    test('designs list should have 5 predefined designs', () {
      final designs = QrDesignModel.designs;
      expect(designs.length, 5);
    });

    test('each design should have a unique id', () {
      final designs = QrDesignModel.designs;
      final ids = designs.map((d) => d.id).toSet();
      expect(ids.length, designs.length);
    });

    test('each design should have a non-empty name', () {
      final designs = QrDesignModel.designs;
      for (final design in designs) {
        expect(design.name.isNotEmpty, true, reason: 'Design ${design.id} has empty name');
      }
    });

    test('house shape designs exist', () {
      final designs = QrDesignModel.designs;
      final houseDesigns =
          designs.where((d) => d.shape == QrDesignShape.house).toList();
      expect(houseDesigns.isNotEmpty, true);
    });

    test('scan_contact design has correct properties', () {
      final designs = QrDesignModel.designs;
      final scanContact = designs.firstWhere((d) => d.id == 'scan_contact');
      expect(scanContact.name, 'Scan Me for Contact');
      expect(scanContact.shape, QrDesignShape.house);
      expect(scanContact.showLabel, true);
      expect(scanContact.showBranding, true);
      expect(scanContact.subtitle, 'BlueEra Safety');
      expect(scanContact.borderWidth, 3.0);
    });

    test('vehicle_safety design has rectangle shape', () {
      final designs = QrDesignModel.designs;
      final vehicleSafety =
          designs.firstWhere((d) => d.id == 'vehicle_safety');
      expect(vehicleSafety.shape, QrDesignShape.rectangle);
      expect(vehicleSafety.subtitle, 'Scan & Visit');
    });

    test('minimal_round design has circle shape', () {
      final designs = QrDesignModel.designs;
      final minimal = designs.firstWhere((d) => d.id == 'minimal_round');
      expect(minimal.shape, QrDesignShape.circle);
    });

    test('rounded_card design has rounded shape', () {
      final designs = QrDesignModel.designs;
      final rounded = designs.firstWhere((d) => d.id == 'rounded_card');
      expect(rounded.shape, QrDesignShape.rounded);
    });

    test('default constructor values are correct', () {
      const design = QrDesignModel(
        id: 'test',
        name: 'Test Design',
        shape: QrDesignShape.rectangle,
      );
      expect(design.backgroundColor, Colors.white);
      expect(design.qrColor, const Color(0xFF1A1A2E));
      expect(design.borderColor, const Color(0xFF1A1A2E));
      expect(design.borderWidth, 2.0);
      expect(design.showLabel, true);
      expect(design.showBranding, true);
      expect(design.subtitle, null);
    });

    test('all shape enum values are covered by designs', () {
      final designs = QrDesignModel.designs;
      final shapes = designs.map((d) => d.shape).toSet();
      expect(shapes.contains(QrDesignShape.house), true);
      expect(shapes.contains(QrDesignShape.rectangle), true);
      expect(shapes.contains(QrDesignShape.circle), true);
      expect(shapes.contains(QrDesignShape.rounded), true);
    });

    test('all designs have valid border width', () {
      final designs = QrDesignModel.designs;
      for (final design in designs) {
        expect(design.borderWidth > 0, true,
            reason: 'Design ${design.id} has invalid border width');
      }
    });

    test('all designs have subtitles', () {
      final designs = QrDesignModel.designs;
      for (final design in designs) {
        expect(design.subtitle != null, true,
            reason: 'Design ${design.id} has no subtitle');
      }
    });
  });

  group('QrDesignShape', () {
    test('enum has 4 values', () {
      expect(QrDesignShape.values.length, 4);
    });

    test('enum contains all expected values', () {
      expect(QrDesignShape.values, contains(QrDesignShape.house));
      expect(QrDesignShape.values, contains(QrDesignShape.rectangle));
      expect(QrDesignShape.values, contains(QrDesignShape.circle));
      expect(QrDesignShape.values, contains(QrDesignShape.rounded));
    });
  });
}
