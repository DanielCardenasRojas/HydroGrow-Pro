import 'package:flutter_test/flutter_test.dart';
import 'package:hydrogrow/main.dart'; // <-- usa el nombre real del paquete

void main() {
  testWidgets('Renderiza la pantalla de login', (tester) async {
    await tester.pumpWidget(const HydroApp()); // ya no MyApp
    // Título del login (CupertinoNavigationBar)
    expect(find.text('Hydro'), findsOneWidget);
  });
}
