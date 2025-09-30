import 'package:flutter/cupertino.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // demo (luego vendrá de tu API)
  double temp = 24.8;
  double soil1 = 42;
  double soil2 = 55;
  bool lightsOn = true;
  bool fan1On = false;
  bool fan2On = false;

  @override
  Widget build(BuildContext context) {
    final avgSoil = (soil1 + soil2) / 2;
    final fansOn = (fan1On ? 1 : 0) + (fan2On ? 1 : 0);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Panel'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() {
            temp += 0.1;
            soil1 = (soil1 - 0.3).clamp(0, 100);
            soil2 = (soil2 - 0.3).clamp(0, 100);
          }),
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // KPIs (cards horizontales)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Kpi(
                      title: 'Temp',
                      value: '${temp.toStringAsFixed(1)} °C',
                      icon: CupertinoIcons.thermometer,
                    ),
                    _Kpi(
                      title: 'Humedad prom.',
                      value: '${avgSoil.toStringAsFixed(0)} %',
                      icon: CupertinoIcons.drop,
                    ),
                    _Kpi(
                      title: 'Luz',
                      value: lightsOn ? 'Encendida' : 'Apagada',
                      icon: CupertinoIcons.lightbulb,
                    ),
                    _Kpi(
                      title: 'Ventilación',
                      value: '$fansOn / 2',
                      icon: CupertinoIcons.wind,
                    ),
                  ],
                ),
              ),
            ),

            // Macetas (inset grouped)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: const Text(
                  'Macetas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _PotTile(name: 'Maceta 1', percent: soil1),
                  _PotTile(name: 'Maceta 2', percent: soil2),
                ],
              ),
            ),

            // Controles globales
            SliverToBoxAdapter(
              child: CupertinoFormSection.insetGrouped(
                header: const Text('Controles'),
                children: [
                  CupertinoFormRow(
                    prefix: const Text('Luz de crecimiento'),
                    child: CupertinoSwitch(
                      value: lightsOn,
                      onChanged: (v) => setState(() => lightsOn = v),
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: const Text('Ventilador 1'),
                    child: CupertinoSwitch(
                      value: fan1On,
                      onChanged: (v) => setState(() => fan1On = v),
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: const Text('Ventilador 2'),
                    child: CupertinoSwitch(
                      value: fan2On,
                      onChanged: (v) => setState(() => fan2On = v),
                    ),
                  ),
                ],
              ),
            ),

            // Placeholder de gráficas
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _Card(
                  height: 140,
                  child: const Center(
                    child: Text('Gráficas históricas (próximamente)'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _Kpi({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _Card(
      width: 180,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: CupertinoColors.activeGreen),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotTile extends StatelessWidget {
  final String name;
  final double percent;
  const _PotTile({required this.name, required this.percent});

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection.insetGrouped(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.star_lefthalf_fill,
                size: 22,
                color: CupertinoColors.systemGrey2,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 16))),
              Text('${percent.toStringAsFixed(0)} %'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _CupertinoLinear(percent: (percent / 100).clamp(0, 1)),
        ),
      ],
    );
  }
}

/// Tarjeta con esquinas iOS (secondarySystemGroupedBackground)
class _Card extends StatelessWidget {
  final double? width, height;
  final Widget child;
  const _Card({this.width, this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Barra de progreso estilo iOS simple
class _CupertinoLinear extends StatelessWidget {
  final double percent; // 0..1
  const _CupertinoLinear({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey4,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: percent,
          child: Container(color: CupertinoColors.activeGreen),
        ),
      ),
    );
  }
}
