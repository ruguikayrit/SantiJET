import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/imalat_block_template.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

const _bg = Color(0xFFF4F7FB);
const _header = Color(0xFF0B1424);
const _blue = Color(0xFF2F6BFF);
const _ink = Color(0xFF1C2430);
const _muted = Color(0xFF8B95A5);
const _line = Color(0xFFE6EBF2);
const _green = Color(0xFF16A34A);
const _orange = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

const _blockColors = [
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFF22C55E),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
];

const _diameters = [8, 10, 12, 14, 16, 18, 20, 22, 25, 28, 32];

enum _Stage { blocks, entry, summary }

/// Keşif imalat satırının devamı: Veri Girişi ve Son Durum.
class ImalatFlowScreen extends ConsumerStatefulWidget {
  const ImalatFlowScreen({super.key, required this.imalatId});

  final String imalatId;

  @override
  ConsumerState<ImalatFlowScreen> createState() => _ImalatFlowScreenState();
}

class _ImalatFlowScreenState extends ConsumerState<ImalatFlowScreen> {
  _Stage _stage = _Stage.blocks;
  var _ready = false;
  var _booted = false;
  int _entryTab = 0;
  int _summaryTab = 0;
  var _showPercent = false;
  final _expanded = <String>{};
  final _copyTargets = <String>{};
  String? _entryBlockId;
  String? _entrySubId;
  String? _focusBlockId;
  List<ImalatBlock> _blocks = const [];
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  SurveyImalat? _imalat() {
    final items = ref.read(surveyProjectProvider).imalats;
    for (final item in items) {
      if (item.id == widget.imalatId) return item;
    }
    return null;
  }

  Future<void> _bootstrap() async {
    if (_booted) return;
    _booted = true;
    final imalat = _imalat();
    if (imalat == null || !mounted) return;
    final blocks = imalat.blocks.isNotEmpty ? imalat.blocks : ImalatBlockTemplate.build(imalat);
    setState(() {
      _blocks = blocks;
      _ready = true;
      if (blocks.isNotEmpty) {
        _expanded.add(blocks.first.id);
        _focusBlockId = blocks.first.id;
      }
    });
    if (imalat.blocks.isEmpty) await _persist();
  }

  Future<void> _persist() async {
    if (!ref.read(canEditActiveProjectProvider)) return;
    try {
      await ref.read(surveyProjectProvider.notifier).saveImalatBlocks(
            imalatId: widget.imalatId,
            blocks: _blocks,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt yazılamadı')),
      );
    }
  }

  void _setStage(_Stage stage) {
    setState(() => _stage = stage);
    _persist();
  }

  ImalatBlock? _blockById(String? id) {
    for (final block in _blocks) {
      if (block.id == id) return block;
    }
    return null;
  }

  ImalatSubWork? _subOf(ImalatBlock? block, String? subId) {
    if (block == null) return null;
    for (final item in block.items) {
      if (item.id == subId) return item;
    }
    return null;
  }

  void _rememberNote(String blockId, String subId, String value) {
    _blocks = [
      for (final block in _blocks)
        if (block.id != blockId)
          block
        else
          block.copyWith(
            items: [
              for (final item in block.items)
                if (item.id != subId) item else item.copyWith(note: value),
            ],
          ),
    ];
  }

  void _replaceSub(String blockId, ImalatSubWork next, {bool persist = true}) {
    setState(() {
      _blocks = [
        for (final block in _blocks)
          if (block.id != blockId)
            block
          else
            block.copyWith(
              items: [
                for (final item in block.items)
                  if (item.id == next.id) next else item,
              ],
            ),
      ];
    });
    if (persist) _persist();
  }

  void _openSub(String blockId, String subId) {
    final sub = _subOf(_blockById(blockId), subId);
    _noteController.text = sub?.note ?? '';
    setState(() {
      _stage = _Stage.entry;
      _entryBlockId = blockId;
      _entrySubId = subId;
      _copyTargets.clear();
    });
  }

  Future<void> _addBlock() async {
    final code = _nextCode();
    final block = ImalatBlock(
      id: 'block-$code-${DateTime.now().microsecondsSinceEpoch}',
      code: code,
      name: '$code Blok',
    );
    setState(() {
      _blocks = [..._blocks, block];
      _expanded.add(block.id);
    });
    await _persist();
  }

  String _nextCode() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final used = _blocks.map((block) => block.code).toSet();
    for (final letter in letters.split('')) {
      if (!used.contains(letter)) return letter;
    }
    return 'Z${_blocks.length + 1}';
  }

  Future<void> _addSub(ImalatBlock block) async {
    final name = await _askText('Alt imalat adı', 'Örn: Radye Temel');
    if (name == null || name.trim().isEmpty) return;
    final item = ImalatSubWork(
      id: 'sub-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      lines: const [
        DiameterLine(diameter: 12, planned: 0, ordered: 0, delivered: 0),
      ],
    );
    setState(() {
      _blocks = [
        for (final current in _blocks)
          if (current.id != block.id) current else current.copyWith(items: [...current.items, item]),
      ];
    });
    await _persist();
  }

  Future<String?> _askText(String title, String hint) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _OwnedField(
        initial: '',
        builder: (ctx, controller) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (text) => Navigator.pop(ctx, text.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAmount(ImalatSubWork sub, DiameterLine line) async {
    final amount = await _askAmount(line.planned);
    if (amount == null) return;
    _replaceSub(
      _entryBlockId!,
      sub.copyWith(
        lines: [
          for (final current in sub.lines)
            if (current.diameter == line.diameter) current.copyWith(planned: amount) else current,
        ],
      ),
    );
  }

  Future<double?> _askAmount(double current) {
    return showDialog<double>(
      context: context,
      builder: (ctx) => _OwnedField(
        initial: AppFormat.tonnage(current),
        builder: (ctx, controller) => AlertDialog(
          title: const Text('Miktar (ton)'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '0,00'),
            onSubmitted: (text) {
              final parsed = _parseAmount(text);
              if (parsed != null) Navigator.pop(ctx, parsed);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () {
                final parsed = _parseAmount(controller.text);
                if (parsed == null) return;
                Navigator.pop(ctx, parsed);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDiameter(ImalatSubWork sub) async {
    final used = sub.lines.map((line) => line.diameter).toSet();
    final available = _diameters.where((diameter) => !used.contains(diameter)).toList();
    if (available.isEmpty || !mounted) return;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Çap Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final diameter in available)
                  ActionChip(
                    label: Text('Ø$diameter'),
                    onPressed: () => Navigator.pop(ctx, diameter),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final lines = [
      ...sub.lines,
      DiameterLine(diameter: picked, planned: 0, ordered: 0, delivered: 0),
    ]..sort((a, b) => a.diameter.compareTo(b.diameter));
    _replaceSub(_entryBlockId!, sub.copyWith(lines: lines));
  }

  Future<void> _copyToImalat(ImalatSubWork sub) async {
    final project = ref.read(surveyProjectProvider);
    final others = project.imalats.where((item) => item.id != widget.imalatId).toList();
    if (others.isEmpty || !mounted) return;
    final picked = await showModalBottomSheet<SurveyImalat>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Diğer imalata kopyala')),
            for (final item in others)
              ListTile(
                title: Text(item.name),
                onTap: () => Navigator.pop(ctx, item),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final blocks = picked.blocks.isNotEmpty ? picked.blocks : ImalatBlockTemplate.build(picked);
    if (blocks.isEmpty) return;
    final copy = sub.copyWith(id: 'sub-${DateTime.now().microsecondsSinceEpoch}');
    final first = blocks.first.copyWith(items: [...blocks.first.items, copy]);
    await ref.read(surveyProjectProvider.notifier).saveImalatBlocks(
          imalatId: picked.id,
          blocks: [first, ...blocks.skip(1)],
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${sub.name} ${picked.name} imalatına kopyalandı')),
    );
  }

  void _copyToBlocks(ImalatSubWork sub) {
    if (_copyTargets.isEmpty) return;
    setState(() {
      _blocks = [
        for (final block in _blocks)
          if (!_copyTargets.contains(block.id) || block.id == _entryBlockId)
            block
          else
            _copySubInto(block, sub),
      ];
      _copyTargets.clear();
    });
    _persist();
  }

  ImalatBlock _copySubInto(ImalatBlock block, ImalatSubWork sub) {
    final exists = block.items.any((item) => item.name == sub.name);
    if (!exists) {
      return block.copyWith(
        items: [
          ...block.items,
          sub.copyWith(id: '${block.id}-${sub.id}'),
        ],
      );
    }
    return block.copyWith(
      items: [
        for (final item in block.items)
          if (item.name != sub.name) item else item.copyWith(lines: sub.lines, note: sub.note),
      ],
    );
  }

  Future<void> _applyTemplate(SurveyImalat imalat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şablonu uygula'),
        content: const Text('Bloklar ve alt imalatlar bu türün standart dağılımına döner. Toplam miktar korunur.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Uygula')),
        ],
      ),
    );
    if (confirmed != true) return;
    final blocks = ImalatBlockTemplate.build(imalat);
    setState(() {
      _blocks = blocks;
      _expanded
        ..clear()
        ..addAll(blocks.take(1).map((block) => block.id));
      _focusBlockId = blocks.isEmpty ? null : blocks.first.id;
    });
    await _persist();
  }

  Future<void> _editProgress(SurveyImalat imalat) async {
    final value = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => _OwnedField(
        initial: imalat.progressPercent.round().toString(),
        builder: (ctx, controller) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Keşif ilerlemesi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(suffixText: '%', labelText: 'Tamamlanma'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
                      if (parsed == null) return;
                      Navigator.pop(ctx, parsed.clamp(0, 100));
                    },
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (value == null) return;
    await ref.read(surveyProjectProvider.notifier).updateImalatProgress(
          imalatId: imalat.id,
          progressPercent: value,
        );
  }

  Future<void> _pickProject() async {
    final projects = ref.read(userProjectsProvider);
    final activeId = ref.read(activeProjectProvider)?.id;
    if (!mounted) return;
    final picked = await showModalBottomSheet<Project>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Proje')),
            for (final project in projects)
              ListTile(
                title: Text(project.name),
                trailing: project.id == activeId ? const Icon(Icons.check, color: _blue) : null,
                onTap: () => Navigator.pop(ctx, project),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked.id == activeId) return;
    await ref.read(projectsControllerProvider).switchProject(picked.id);
    if (mounted) context.pop();
  }

  void _leaveOrPop() {
    if (_stage == _Stage.blocks) {
      context.pop();
      return;
    }
    _setStage(_Stage.blocks);
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(surveyProjectProvider);
    final active = ref.watch(activeProjectProvider);
    SurveyImalat? imalat;
    for (final item in project.imalats) {
      if (item.id == widget.imalatId) imalat = item;
    }
    final step = _stage == _Stage.summary ? 1 : 0;

    return PopScope(
      canPop: _stage == _Stage.blocks,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _stage = _Stage.blocks);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              _FlowHeader(
                title: imalat?.name ?? 'Keşif',
                step: step,
                onBack: _leaveOrPop,
                onStep: (index) => _setStage(index == 0 ? _Stage.blocks : _Stage.summary),
              ),
              Expanded(
                child: !_ready || imalat == null
                    ? const Center(child: CircularProgressIndicator(color: _blue))
                    : _body(imalat, active?.name ?? project.projectName),
              ),
              if (_ready && imalat != null) _footer(imalat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(SurveyImalat imalat, String projectName) {
    return switch (_stage) {
      _Stage.blocks => _blocksBody(imalat, projectName),
      _Stage.entry => _entryBody(imalat),
      _Stage.summary => _summaryBody(imalat),
    };
  }

  Widget _footer(SurveyImalat imalat) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    if (_stage == _Stage.summary) {
      return _SummaryActions(
        bottom: bottom,
        onReport: () => context.push(AppRoutes.analysis),
        onOrder: () => context.push(AppRoutes.newOrder),
        onDelivery: () => context.push(AppRoutes.newDelivery),
        onMore: () => _editProgress(imalat),
      );
    }
    if (_stage == _Stage.entry) {
      return _TwinBar(
        bottom: bottom,
        onBack: () => _setStage(_Stage.blocks),
        onNext: () => _setStage(_Stage.summary),
      );
    }
    final total = _blocks.fold<double>(0, (sum, block) => sum + block.planned);
    return _NextBar(
      bottom: bottom,
      label: 'Proje Toplamı (${imalat.name})',
      value: '${AppFormat.tonnage(total)} t',
      onNext: () => _setStage(_Stage.summary),
    );
  }

  Widget _blocksBody(SurveyImalat imalat, String projectName) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Row(
          children: [
            Expanded(child: _ProjectChip(name: projectName, onTap: _pickProject)),
            const SizedBox(width: 8),
            _ToolChip(icon: Icons.description_outlined, label: 'Şablon', onTap: () => _applyTemplate(imalat)),
            const SizedBox(width: 8),
            _ToolChip(icon: Icons.settings_outlined, label: 'Ayarlar', onTap: () => _editProgress(imalat)),
          ],
        ),
        const SizedBox(height: 12),
        _TabBar(
          labels: const ['Bloklar', 'Alt İmalatlar', 'Çaplar', 'Açıklama'],
          index: _entryTab,
          onChanged: (index) => setState(() => _entryTab = index),
        ),
        const SizedBox(height: 12),
        if (_entryTab == 0) ..._blockCards(),
        if (_entryTab == 1) ..._flatSubs(),
        if (_entryTab == 2) _diameterRollup(),
        if (_entryTab == 3) ..._notesList(),
      ],
    );
  }

  List<Widget> _blockCards() {
    return [
      for (var i = 0; i < _blocks.length; i++) ...[
        _BlockCard(
          block: _blocks[i],
          color: _blockColors[i % _blockColors.length],
          expanded: _expanded.contains(_blocks[i].id),
          onToggle: () => setState(() {
            if (!_expanded.add(_blocks[i].id)) _expanded.remove(_blocks[i].id);
          }),
          onOpen: (subId) => _openSub(_blocks[i].id, subId),
          onAdd: () => _addSub(_blocks[i]),
        ),
        const SizedBox(height: 10),
      ],
      _DashedButton(label: 'Yeni Blok Ekle', icon: Icons.add, onTap: _addBlock),
    ];
  }

  List<Widget> _flatSubs() {
    final tiles = <Widget>[];
    for (var i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      tiles.add(Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(block.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
      ));
      for (final item in block.items) {
        tiles.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SubTile(
            item: item,
            thumb: _thumbFor(item.name),
            onTap: () => _openSub(block.id, item.id),
          ),
        ));
      }
    }
    if (tiles.isEmpty) {
      tiles.add(const _EmptyHint('Alt imalat yok'));
    }
    return tiles;
  }

  Widget _diameterRollup() {
    final totals = <int, double>{};
    for (final block in _blocks) {
      for (final item in block.items) {
        for (final line in item.lines) {
          totals.update(line.diameter, (value) => value + line.planned, ifAbsent: () => line.planned);
        }
      }
    }
    final whole = totals.values.fold<double>(0, (sum, value) => sum + value);
    final keys = totals.keys.toList()..sort();
    if (keys.isEmpty) return const _EmptyHint('Çap yok');
    return _WhiteCard(
      child: Column(
        children: [
          const _TableHead(cells: ['Çap (mm)', 'Miktar (ton)', 'Ağırlık Oranı']),
          for (final diameter in keys)
            _DiameterRow(
              diameter: diameter,
              amount: totals[diameter] ?? 0,
              ratio: _share(totals[diameter] ?? 0, whole),
              onAmount: null,
              onDelete: null,
            ),
          _TotalRow(amount: whole),
        ],
      ),
    );
  }

  List<Widget> _notesList() {
    final tiles = <Widget>[];
    for (final block in _blocks) {
      for (final item in block.items) {
        tiles.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _WhiteCard(
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink, fontSize: 14)),
              subtitle: Text(
                item.note.isEmpty ? 'Açıklama yok' : item.note,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFB0B8C4)),
              onTap: () => _openSub(block.id, item.id),
            ),
          ),
        ));
      }
    }
    if (tiles.isEmpty) tiles.add(const _EmptyHint('Açıklama yok'));
    return tiles;
  }

  Widget _entryBody(SurveyImalat imalat) {
    final block = _blockById(_entryBlockId) ?? (_blocks.isEmpty ? null : _blocks.first);
    final sub = _subOf(block, _entrySubId) ?? (block != null && block.items.isNotEmpty ? block.items.first : null);
    if (block == null || sub == null) return const _EmptyHint('Alt imalat seçin');
    final others = _blocks.where((item) => item.id != block.id).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        _WhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _LetterBadge(code: block.code, color: _colorFor(block)),
              const SizedBox(width: 10),
              Expanded(
                child: PopupMenuButton<String>(
                  onSelected: (id) {
                    final next = _blockById(id);
                    final match = next?.items.cast<ImalatSubWork?>().firstWhere(
                          (item) => item?.name == sub.name,
                          orElse: () => next.items.isEmpty ? null : next.items.first,
                        );
                    if (match == null) return;
                    _openSub(id, match.id);
                  },
                  itemBuilder: (context) => [
                    for (final item in _blocks)
                      PopupMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          block.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: _muted),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Blok Toplamı', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600)),
                  Text(
                    '${AppFormat.tonnage(block.planned)} t',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _WhiteCard(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () => _pickSub(block),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(_thumbFor(sub.name), width: 52, height: 52, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alt İmalat Türü', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600)),
                      Text(sub.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFB0B8C4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Bu imalat için toplam miktar (ton)', style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              AppFormat.tonnage(sub.planned),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _ink, height: 1),
            ),
            const Spacer(),
            _OutlineAction(
              icon: Icons.copy_outlined,
              label: 'Diğer İmalata Kopyala',
              onTap: () => _copyToImalat(sub),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('Çap Bazlı Miktar Girişi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
            ),
            IconButton(
              onPressed: () => _showHelp(),
              icon: const Icon(Icons.help_outline, size: 18, color: _muted),
              visualDensity: VisualDensity.compact,
            ),
            TextButton.icon(
              onPressed: () => _addDiameter(sub),
              icon: const Icon(Icons.add, size: 18, color: _blue),
              label: const Text('Çap Ekle', style: TextStyle(color: _blue, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        _WhiteCard(
          child: Column(
            children: [
              const _TableHead(cells: ['Çap (mm)', 'Miktar (ton)', 'Ağırlık Oranı', 'İşlemler']),
              for (final line in sub.lines)
                _DiameterRow(
                  diameter: line.diameter,
                  amount: line.planned,
                  ratio: _share(line.planned, sub.planned),
                  onAmount: () => _editAmount(sub, line),
                  onDelete: () => _replaceSub(
                    block.id,
                    sub.copyWith(lines: sub.lines.where((item) => item.diameter != line.diameter).toList()),
                  ),
                ),
              _TotalRow(amount: sub.planned),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _WhiteCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Diğer Bloklara Kopyala', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 4),
              const Text(
                'Aynı çap ve miktarlar seçilen bloklara kopyalayın.',
                style: TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: [
                        for (final other in others)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _copyTargets.contains(other.id),
                                activeColor: _blue,
                                visualDensity: VisualDensity.compact,
                                onChanged: (checked) => setState(() {
                                  if (checked ?? false) {
                                    _copyTargets.add(other.id);
                                  } else {
                                    _copyTargets.remove(other.id);
                                  }
                                }),
                              ),
                              Text(other.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _copyTargets.isEmpty ? null : () => _copyToBlocks(sub),
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      minimumSize: const Size(84, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Kopyala'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Açıklama (opsiyonel)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 6),
        TextField(
          controller: _noteController,
          minLines: 2,
          maxLines: 3,
          onChanged: (value) => _rememberNote(block.id, sub.id, value),
          onEditingComplete: _persist,
          decoration: InputDecoration(
            hintText: 'Açıklama yazın',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue)),
          ),
        ),
      ],
    );
  }

  Future<void> _pickSub(ImalatBlock block) async {
    final picked = await showModalBottomSheet<ImalatSubWork>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in block.items)
              ListTile(title: Text(item.name), onTap: () => Navigator.pop(ctx, item)),
          ],
        ),
      ),
    );
    if (picked == null) return;
    _openSub(block.id, picked.id);
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çap bazlı miktar'),
        content: const Text('Her çapın ton miktarını girin. Ağırlık oranı, bu alt imalatın toplamına göre hesaplanır.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
  }

  Color _colorFor(ImalatBlock block) {
    final index = _blocks.indexWhere((item) => item.id == block.id);
    return _blockColors[(index < 0 ? 0 : index) % _blockColors.length];
  }

  Widget _summaryBody(SurveyImalat imalat) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        _TabBar(
          labels: const ['Proje Özeti', 'Blok Bazlı', 'Alt İmalat Bazlı', 'Çap Bazlı'],
          index: _summaryTab,
          onChanged: (index) => setState(() => _summaryTab = index),
        ),
        const SizedBox(height: 12),
        if (_summaryTab == 0) ...[
          _SummaryHero(imalat: imalat),
          const SizedBox(height: 10),
          _FormulaBanner(onDetail: () => _showFormula()),
          const SizedBox(height: 14),
          _sectionTitle('Blok Bazlı Durum'),
          const SizedBox(height: 8),
          _sliceTable(_blockSlices(imalat), firstFlexLabel: 'Blok'),
          const SizedBox(height: 14),
          _focusSubs(imalat),
        ],
        if (_summaryTab == 1) ...[
          _sectionTitle('Blok Bazlı Durum'),
          const SizedBox(height: 8),
          _sliceTable(_blockSlices(imalat), firstFlexLabel: 'Blok'),
        ],
        if (_summaryTab == 2) ...[
          _sectionTitle('Alt İmalat Bazlı Durum'),
          const SizedBox(height: 8),
          _sliceTable(_subSlices(imalat), firstFlexLabel: 'Alt İmalat'),
        ],
        if (_summaryTab == 3) ...[
          _sectionTitle('Çap Bazlı Durum'),
          const SizedBox(height: 8),
          _sliceTable(_diameterSlices(imalat), firstFlexLabel: 'Çap'),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink))),
        PopupMenuButton<bool>(
          onSelected: (value) => setState(() => _showPercent = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: false, child: Text('Tonaj (t)')),
            PopupMenuItem(value: true, child: Text('Yüzde')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _showPercent ? 'Yüzde' : 'Tonaj (t)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: _muted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _focusSubs(SurveyImalat imalat) {
    final block = _blockById(_focusBlockId) ?? (_blocks.isEmpty ? null : _blocks.first);
    if (block == null) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${block.name} Alt İmalatları',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _summaryTab = 2),
              child: const Text('Tümünü Gör', style: TextStyle(color: _blue, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        _sliceTable(_slicesFor(block, imalat), firstFlexLabel: 'Alt İmalat'),
      ],
    );
  }

  void _showFormula() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesap'),
        content: const Text(
          'Kalan Sipariş İhtiyacı = Planlanan − Sipariş Edilen\n\nBekleyen Sipariş = Sipariş Edilen − Teslim Alınan',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
  }

  List<_Slice> _blockSlices(SurveyImalat imalat) {
    return [
      for (final block in _blocks) ..._slicesFor(block, imalat, label: block.name, asBlock: true),
    ];
  }

  List<_Slice> _slicesFor(ImalatBlock block, SurveyImalat imalat, {String? label, bool asBlock = false}) {
    final total = _blocks.fold<double>(0, (sum, item) => sum + item.planned);
    final blockOrdered = total > 0 ? imalat.ordered * (block.planned / total) : 0.0;
    final blockDelivered = total > 0 ? imalat.delivered * (block.planned / total) : 0.0;
    if (asBlock) {
      return [
        _Slice(block.name, block.planned, blockOrdered, blockDelivered, imalat.progressPercent),
      ];
    }
    final subTotal = block.planned;
    return [
      for (final item in block.items)
        _Slice(
          item.name,
          item.planned,
          subTotal > 0 ? blockOrdered * (item.planned / subTotal) : 0,
          subTotal > 0 ? blockDelivered * (item.planned / subTotal) : 0,
          imalat.progressPercent,
        ),
    ];
  }

  List<_Slice> _subSlices(SurveyImalat imalat) {
    return [
      for (final block in _blocks) ..._slicesFor(block, imalat),
    ];
  }

  List<_Slice> _diameterSlices(SurveyImalat imalat) {
    final planned = <int, double>{};
    for (final block in _blocks) {
      for (final item in block.items) {
        for (final line in item.lines) {
          planned.update(line.diameter, (value) => value + line.planned, ifAbsent: () => line.planned);
        }
      }
    }
    final whole = planned.values.fold<double>(0, (sum, value) => sum + value);
    final keys = planned.keys.toList()..sort();
    return [
      for (final diameter in keys)
        _Slice(
          'Ø$diameter',
          planned[diameter] ?? 0,
          whole > 0 ? imalat.ordered * ((planned[diameter] ?? 0) / whole) : 0,
          whole > 0 ? imalat.delivered * ((planned[diameter] ?? 0) / whole) : 0,
          imalat.progressPercent,
        ),
    ];
  }

  Widget _sliceTable(List<_Slice> rows, {required String firstFlexLabel}) {
    return _WhiteCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                SizedBox(width: 78, child: Text(firstFlexLabel, style: _headStyle)),
                for (final label in const ['Planlanan', 'Sipariş', 'Gelen', 'Bekleyen', 'Kalan', '%'])
                  Expanded(child: Text(label, textAlign: TextAlign.center, style: _headStyle)),
              ],
            ),
          ),
          for (final row in rows)
            InkWell(
              onTap: () {
                final block = _blocks.cast<ImalatBlock?>().firstWhere(
                      (item) => item?.name == row.label,
                      orElse: () => null,
                    );
                if (block == null) return;
                setState(() => _focusBlockId = block.id);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(
                        row.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink),
                      ),
                    ),
                    _MetricCell(value: row.planned, whole: row.planned, color: _blue, percent: _showPercent),
                    _MetricCell(value: row.ordered, whole: row.planned, color: _blue, percent: _showPercent),
                    _MetricCell(value: row.delivered, whole: row.planned, color: _green, percent: _showPercent),
                    _MetricCell(value: row.pending, whole: row.planned, color: _orange, percent: _showPercent),
                    _MetricCell(value: row.remaining, whole: row.planned, color: _red, percent: _showPercent),
                    Expanded(
                      child: Text(
                        '%${row.progress.round()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Slice {
  const _Slice(this.label, this.planned, this.ordered, this.delivered, this.progress);

  final String label;
  final double planned;
  final double ordered;
  final double delivered;
  final double progress;

  double get pending => (ordered - delivered).clamp(0, double.infinity);
  double get remaining => (planned - ordered).clamp(0, double.infinity);
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    required this.step,
    required this.onBack,
    required this.onStep,
  });

  final String title;
  final int step;
  final VoidCallback onBack;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _header,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(_thumbFor(title), width: 36, height: 36, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KEŞİF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF9AA8BC),
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
                    ),
                  ],
                ),
              ),
              _StepMark(index: 0, label: 'Veri Girişi', active: step == 0, done: step > 0, onTap: () => onStep(0)),
              Container(
                width: 22,
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: step > 0 ? _blue : const Color(0xFF334155),
              ),
              _StepMark(index: 1, label: 'Son Durum', active: step == 1, done: false, onTap: () => onStep(1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepMark extends StatelessWidget {
  const _StepMark({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = active || done;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? _blue : const Color(0xFF1C2838),
                shape: BoxShape.circle,
                border: Border.all(color: filled ? _blue : const Color(0xFF334155)),
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: filled ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Proje', style: TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name.isEmpty ? 'Proje' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: _muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: _blue),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Material(
                color: i == index ? _blue : Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: i == index ? _blue : _line),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: i == index ? Colors.white : _ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    required this.color,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    required this.onAdd,
  });

  final ImalatBlock block;
  final Color color;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color(0x0C1C2430), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  _LetterBadge(code: block.code, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(block.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
                        const SizedBox(height: 2),
                        Text(
                          '${block.items.length} alt imalat · ${AppFormat.tonnage(block.planned)} t',
                          style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: _muted),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  for (final item in block.items) ...[
                    _SubTile(item: item, thumb: _thumbFor(item.name), onTap: () => onOpen(item.id)),
                    const SizedBox(height: 8),
                  ],
                  _DashedButton(label: 'Alt İmalat Ekle', icon: Icons.add, onTap: onAdd),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.code, required this.color});

  final String code;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        code,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  const _SubTile({required this.item, required this.thumb, required this.onTap});

  final ImalatSubWork item;
  final String thumb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diameters = item.lines.map((line) => line.diameter).toList()..sort();
    final shown = diameters.take(4).map((diameter) => 'Ø$diameter').join('  ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(thumb, width: 44, height: 44, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                    Text(
                      diameters.isEmpty ? 'Çap yok' : 'Çap: $shown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                '${AppFormat.tonnage(item.planned)} t',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB0B8C4), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: const _DashPainter(),
          child: SizedBox(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: _blue),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _blue)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)));
    final paint = Paint()
      ..color = const Color(0xFFB9C6D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: child,
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead({required this.cells});

  final List<String> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: Text(
                cell,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiameterRow extends StatelessWidget {
  const _DiameterRow({
    required this.diameter,
    required this.amount,
    required this.ratio,
    required this.onAmount,
    required this.onDelete,
  });

  final int diameter;
  final double amount;
  final int ratio;
  final VoidCallback? onAmount;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _diameterColor(diameter).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ø$diameter',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _diameterColor(diameter)),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onAmount,
              child: Container(
                height: 34,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  AppFormat.tonnage(amount),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '%$ratio',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted),
            ),
          ),
          if (onDelete != null)
            Expanded(
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: _muted, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Toplam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          ),
          Text('${AppFormat.tonnage(amount)} t', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(width: 16),
          const Text('%100', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted)),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: _blue),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.imalat});

  final SurveyImalat imalat;

  @override
  Widget build(BuildContext context) {
    final progress = imalat.progressPercent.clamp(0, 100).toDouble();
    final pending = (imalat.ordered - imalat.delivered).clamp(0, double.infinity).toDouble();
    final remaining = (imalat.planned - imalat.ordered).clamp(0, double.infinity).toDouble();
    final accent = _accentFor(imalat.name);
    return _WhiteCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(_thumbFor(imalat.name), width: 64, height: 64, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(imalat.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppFormat.tonnage(imalat.planned)} t',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, height: 1),
                              ),
                              const SizedBox(height: 2),
                              const Text('Planlanan Toplam', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '%${progress.round()}',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent, height: 1),
                            ),
                            const SizedBox(height: 2),
                            const Text('Tamamlanma', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 5,
              backgroundColor: _line,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatBox(value: imalat.ordered, whole: imalat.planned, label: 'Sipariş Edilen', color: _blue),
              const SizedBox(width: 6),
              _StatBox(value: imalat.delivered, whole: imalat.planned, label: 'Teslim Alınan', color: _green),
              const SizedBox(width: 6),
              _StatBox(value: pending, whole: imalat.planned, label: 'Bekleyen Sipariş', color: _orange),
              const SizedBox(width: 6),
              _StatBox(value: remaining, whole: imalat.planned, label: 'Kalan Sipariş İht.', color: _red),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.whole, required this.label, required this.color});

  final double value;
  final double whole;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(color: const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            FittedBox(
              child: Text(
                '${AppFormat.tonnage(value)} t',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, height: 1.15, fontWeight: FontWeight.w600, color: _muted),
            ),
            const SizedBox(height: 3),
            Text('%${_share(value, whole)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _FormulaBanner extends StatelessWidget {
  const _FormulaBanner({required this.onDetail});

  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _blue, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Kalan Sipariş İhtiyacı = Planlanan − Sipariş Edilen\nBekleyen Sipariş = Sipariş Edilen − Teslim Alınan',
              style: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, color: _ink),
            ),
          ),
          TextButton(
            onPressed: onDetail,
            child: const Text('Detay', style: TextStyle(color: _blue, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.value,
    required this.whole,
    required this.color,
    required this.percent,
  });

  final double value;
  final double whole;
  final Color color;
  final bool percent;

  @override
  Widget build(BuildContext context) {
    final shown = percent ? '%${_share(value, whole)}' : AppFormat.tonnage(value);
    final width = whole <= 0 ? 0.0 : (value / whole).clamp(0.0, 1.0);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Text(
              shown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: width == 0 ? 0.04 : width,
                child: Container(height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextBar extends StatelessWidget {
  const _NextBar({required this.bottom, required this.label, required this.value, required this.onNext});

  final double bottom;
  final String label;
  final String value;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
              ],
            ),
          ),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              minimumSize: const Size(132, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sonraki  →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _TwinBar extends StatelessWidget {
  const _TwinBar({required this.bottom, required this.onBack, required this.onNext});

  final double bottom;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Geri'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sonraki  →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryActions extends StatelessWidget {
  const _SummaryActions({
    required this.bottom,
    required this.onReport,
    required this.onOrder,
    required this.onDelivery,
    required this.onMore,
  });

  final double bottom;
  final VoidCallback onReport;
  final VoidCallback onOrder;
  final VoidCallback onDelivery;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 6, 12, 6 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          _Action(icon: Icons.bar_chart_rounded, label: 'Rapor', color: _ink, onTap: onReport),
          _Action(icon: Icons.note_add_outlined, label: 'Sipariş Ekle', color: _blue, onTap: onOrder),
          _Action(icon: Icons.local_shipping_outlined, label: 'Teslimat Ekle', color: _green, onTap: onDelivery),
          const Spacer(),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onMore,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                child: const Icon(Icons.grid_view_rounded, color: _ink, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _OwnedField extends StatefulWidget {
  const _OwnedField({required this.initial, required this.builder});

  final String initial;
  final Widget Function(BuildContext context, TextEditingController controller) builder;

  @override
  State<_OwnedField> createState() => _OwnedFieldState();
}

class _OwnedFieldState extends State<_OwnedField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(child: Text(text, style: const TextStyle(color: _muted, fontWeight: FontWeight.w600))),
    );
  }
}

const _headStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _muted);

int _share(double part, double whole) {
  if (whole <= 0) return 0;
  return (part / whole * 100).round().clamp(0, 999);
}

double? _parseAmount(String raw) {
  var text = raw.trim().replaceAll(' ', '');
  if (text.isEmpty) return 0;
  if (text.contains(',')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(text);
}

String _foldName(String name) {
  const map = {
    'ş': 's',
    'Ş': 's',
    'ı': 'i',
    'I': 'i',
    'İ': 'i',
    'ö': 'o',
    'Ö': 'o',
    'ü': 'u',
    'Ü': 'u',
    'ğ': 'g',
    'Ğ': 'g',
    'ç': 'c',
    'Ç': 'c',
  };
  final buffer = StringBuffer();
  for (final rune in name.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char.toLowerCase());
  }
  return buffer.toString();
}

String _thumbFor(String name) {
  final normalized = _foldName(name);
  if (normalized.contains('temel')) return 'assets/images/kesif_temel.jpg';
  if (normalized.contains('kolon')) return 'assets/images/kesif_kolon.jpg';
  if (normalized.contains('perde')) return 'assets/images/kesif_perde.jpg';
  if (normalized.contains('kiris')) return 'assets/images/kesif_kiris.jpg';
  if (normalized.contains('doseme')) return 'assets/images/kesif_doseme.jpg';
  if (normalized.contains('merdiven')) return 'assets/images/kesif_merdiven.jpg';
  return 'assets/images/kesif_imalat.jpg';
}

Color _accentFor(String name) {
  final normalized = _foldName(name);
  if (normalized.contains('doseme') || normalized.contains('kiris')) return const Color(0xFF8B5CF6);
  if (normalized.contains('merdiven') || normalized.contains('perde')) return _orange;
  return _blue;
}

Color _diameterColor(int diameter) {
  return switch (diameter) {
    8 => const Color(0xFF7C3AED),
    10 => const Color(0xFF3B82F6),
    12 => const Color(0xFFEC4899),
    14 => const Color(0xFFF59E0B),
    16 => const Color(0xFFEF4444),
    18 => const Color(0xFF14B8A6),
    20 => const Color(0xFF6366F1),
    22 => const Color(0xFF0EA5E9),
    25 => const Color(0xFF84CC16),
    28 => const Color(0xFFF97316),
    _ => const Color(0xFF64748B),
  };
}
