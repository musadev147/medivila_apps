import 'package:flutter_test/flutter_test.dart';
import 'package:medivila_apps/constants/app_config.dart';
import 'package:medivila_apps/models/medivila_models.dart';
import 'package:medivila_apps/main.dart';

void main() {
  test('Bangladeshi phone validation normalizes country code only', () {
    expect(AppConfig.isValidBdPhone('01712345678'), isTrue);
    expect(AppConfig.isValidBdPhone('+8801712345678'), isTrue);
    expect(AppConfig.isValidBdPhone('8801712345678'), isTrue);
    expect(AppConfig.isValidBdPhone('0171234567'), isFalse);
    expect(AppConfig.isValidBdPhone('0171234567x'), isFalse);
  });

  test(
    'bootstrap categories retain parent IDs for home category filtering',
    () {
      final bootstrap = BootstrapData.fromJson({
        'categories': [
          {'id': 1, 'name': 'Parent', 'slug': 'parent', 'parent_id': null},
          {'id': 2, 'name': 'Child', 'slug': 'child', 'parent_id': 1},
        ],
      });

      expect(bootstrap.categories[0].parentId, isNull);
      expect(bootstrap.categories[1].parentId, 1);
      expect(
        bootstrap.categories.where((category) => category.parentId == null),
        hasLength(1),
      );
    },
  );

  test('nested categories inherit their parent ID', () {
    final category = CategoryItem.fromJson({
      'id': 1,
      'name': 'Parent',
      'slug': 'parent',
      'children': [
        {'id': 2, 'name': 'Child', 'slug': 'child'},
      ],
    });

    expect(category.parentId, isNull);
    expect(category.children.single.parentId, 1);
  });

  test('product detail extracts and strips HTML from homepage description', () {
    final product = MedicineProduct.fromJson({
      'id': 369,
      'slug': 'portable-turbo-fan',
      'name': 'Portable Turbo Fan',
      'homepage': {
        'headline': 'High Speed Mini Portable Turbo Fan',
        'description': '<h2>Cooling Turbo Fan</h2><p>4000mAh battery</p><ul><li>Portable</li></ul>',
      },
    });

    expect(product.description, contains('Cooling Turbo Fan'));
    expect(product.description, contains('4000mAh battery'));
    expect(product.description, contains('• Portable'));
    expect(product.description, isNot(contains('<')));
  });

  testWidgets('MedivilaApp basic smoke test', (WidgetTester tester) async {
    expect(const MedivilaApp(), isNotNull);
  });
}
