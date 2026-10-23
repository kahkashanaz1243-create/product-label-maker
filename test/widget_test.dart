import 'package:flutter_test/flutter_test.dart';
import 'package:product_label_maker/main.dart';

void main() {
  testWidgets('Product Label Maker app starts', (tester) async {
    await tester.pumpWidget(const ProductLabelMakerApp());

    expect(find.text('Product Label Maker'), findsOneWidget);
  });
}
