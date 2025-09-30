import 'package:flutter/cupertino.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});
  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  final _pots = [
    PotState(name: 'Maceta 1', moisture: 42, target: 55, auto: false),
    PotState(name: 'Maceta 2', moisture: 55, target: 55, auto: true),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Plantas')),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _pots.length,
          itemBuilder: (c, i) => _PlantSection(
            state: _pots[i],
            onChanged: (s) => setState(() => _pots[i] = s),
          ),
        ),
      ),
    );
  }
}

class PotState {
  final String name;
  final double moisture;
  final double target;
  final bool auto;
  final DateTime? lastWatered;
  PotState({
    required this.name,
    required this.moisture,
    required this.target,
    required this.auto,
    this.lastWatered,
  });
  PotState copyWith({
    String? name,
    double? moisture,
    double? target,
    bool? auto,
    DateTime? lastWatered,
  }) => PotState(
    name: name ?? this.name,
    moisture: moisture ?? this.moisture,
    target: target ?? this.target,
    auto: auto ?? this.auto,
    lastWatered: lastWatered ?? this.lastWatered,
  );
}

class _PlantSection extends StatelessWidget {
  final PotState state;
  final ValueChanged<PotState> onChanged;
  const _PlantSection({required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection.insetGrouped(
      header: Text(state.name),
      children: [
        _RowText('Humedad actual', '${state.moisture.toStringAsFixed(0)} %'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _CupertinoLinear(percent: (state.moisture / 100).clamp(0, 1)),
        ),
        CupertinoFormRow(
          prefix: const Text('Auto-riego'),
          child: CupertinoSwitch(
            value: state.auto,
            onChanged: (v) => onChanged(state.copyWith(auto: v)),
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Objetivo humedad'),
          child: SizedBox(
            width: 180,
            child: CupertinoSlider(
              value: state.target,
              min: 30,
              max: 80,
              divisions: 10,
              onChanged: (v) => onChanged(state.copyWith(target: v)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.lastWatered == null
                      ? 'Último riego —'
                      : 'Último riego: ${state.lastWatered}',
                  style: const TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: CupertinoColors.activeGreen,
                onPressed: () =>
                    onChanged(state.copyWith(lastWatered: DateTime.now())),
                child: const Text('Regar ahora'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RowText extends StatelessWidget {
  final String left, right;
  const _RowText(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(left)),
          Text(
            right,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }
}

class _CupertinoLinear extends StatelessWidget {
  final double percent;
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
