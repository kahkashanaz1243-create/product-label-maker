import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

void main() => runApp(const ProductLabelMakerApp());

const Color brandGreen = Color(0xFF087F68);
const Color pageBg = Color(0xFFF4F7F6);

class ProductLabelMakerApp extends StatelessWidget {
  const ProductLabelMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Label Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brandGreen),
        scaffoldBackgroundColor: pageBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBg,
          foregroundColor: Color(0xFF153A32),
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE5E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE5E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: brandGreen, width: 1.6),
          ),
        ),
      ),
      home: const HomeDashboard(),
    );
  }
}

class ProductLabel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String quantity;
  final String mrp;
  final String salePrice;
  final String batch;
  final String mfg;
  final String expiry;
  final String manufacturer;
  final String ingredients;
  final String barcodeValue;
  final String qrValue;
  final String language;
  final String size;
  final double customWidth;
  final double customHeight;
  final String theme;

  const ProductLabel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.quantity,
    required this.mrp,
    required this.salePrice,
    required this.batch,
    required this.mfg,
    required this.expiry,
    required this.manufacturer,
    required this.ingredients,
    required this.barcodeValue,
    required this.qrValue,
    required this.language,
    required this.size,
    required this.customWidth,
    required this.customHeight,
    required this.theme,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'quantity': quantity,
    'mrp': mrp,
    'salePrice': salePrice,
    'batch': batch,
    'mfg': mfg,
    'expiry': expiry,
    'manufacturer': manufacturer,
    'ingredients': ingredients,
    'barcodeValue': barcodeValue,
    'qrValue': qrValue,
    'language': language,
    'size': size,
    'customWidth': customWidth,
    'customHeight': customHeight,
    'theme': theme,
  };

  factory ProductLabel.fromJson(Map<String, dynamic> j) =>
      ProductLabel(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        brand: '${j['brand'] ?? ''}',
        category: '${j['category'] ?? ''}',
        quantity: '${j['quantity'] ?? ''}',
        mrp: '${j['mrp'] ?? ''}',
        salePrice: '${j['salePrice'] ?? ''}',
        batch: '${j['batch'] ?? ''}',
        mfg: '${j['mfg'] ?? ''}',
        expiry: '${j['expiry'] ?? ''}',
        manufacturer: '${j['manufacturer'] ?? ''}',
        ingredients: '${j['ingredients'] ?? ''}',
        barcodeValue: '${j['barcodeValue'] ?? ''}',
        qrValue: '${j['qrValue'] ?? ''}',
        language: '${j['language'] ?? 'both'}',
        size: '${j['size'] ?? '3 x 2 inch'}',
        customWidth:
            (j['customWidth'] as num?)?.toDouble() ?? 3,
        customHeight:
            (j['customHeight'] as num?)?.toDouble() ?? 2,
        theme: '${j['theme'] ?? 'Green'}',
      );
}

class LabelStore {
  static const _key = 'product_labels_v2';

  static Future<List<ProductLabel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    return raw.map((e) {
      try {
        return ProductLabel.fromJson(
          jsonDecode(e) as Map<String, dynamic>,
        );
      } catch (_) {
        return null;
      }
    }).whereType<ProductLabel>().toList();
  }

  static Future<void> save(List<ProductLabel> labels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      labels.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _count = 0;

  Future<void> _refreshCount() async {
    final labels = await LabelStore.load();
    if (mounted) setState(() => _count = labels.length);
  }

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Label Maker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings & print help',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _open(const PrintHelpPage()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF086B59),
                  Color(0xFF35A98A),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sell_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(height: 18),
                Text(
                  'Professional Product Labels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Offline • PDF • Print • Barcode / QR',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _DashboardTile(
                  icon: Icons.add_box_outlined,
                  title: 'Create Label',
                  subtitle: 'नया लेबल बनाएं',
                  color: brandGreen,
                  onTap: () => _open(const LabelEditorPage()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardTile(
                  icon: Icons.folder_copy_outlined,
                  title: 'My Labels',
                  subtitle: 'सेव लेबल: $_count',
                  color: const Color(0xFF3467A6),
                  onTap: () => _open(const SavedLabelsPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashboardTile(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Templates',
                  subtitle: 'रेडी डिजाइन',
                  color: const Color(0xFF8755A5),
                  onTap: () => _open(const TemplatesPage()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardTile(
                  icon: Icons.print_outlined,
                  title: 'Printer & Export',
                  subtitle: 'PDF / Print',
                  color: const Color(0xFFB66C24),
                  onTap: () => _open(const PrintHelpPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'काम शुरू करें',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          const _FeatureRow(
            icon: Icons.calendar_month_outlined,
            title: 'तारीख चुनें',
            subtitle: 'निर्माण और एक्सपायरी के लिए कैलेंडर',
          ),
          const _FeatureRow(
            icon: Icons.qr_code_2,
            title: 'Barcode / QR',
            subtitle: 'उत्पाद कोड और QR डेटा जोड़ें',
          ),
          const _FeatureRow(
            icon: Icons.straighten,
            title: 'Custom Size',
            subtitle: 'अपनी चौड़ाई और ऊंचाई सेट करें',
          ),
          const _FeatureRow(
            icon: Icons.save_outlined,
            title: 'Offline Storage',
            subtitle: 'लेबल इसी फोन में सेव रहते हैं',
          ),
          const SizedBox(height: 12),
          const Text(
            'ध्यान दें: उत्पाद के प्रकार के अनुसार आवश्यक '
            'कानूनी घोषणाएं अलग हो सकती हैं। प्रिंट करने से '
            'पहले विवरण जांचें.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2EAE7)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 29),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFE2F2EC),
      child: Icon(icon, color: brandGreen),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(subtitle),
  );
}

class LabelEditorPage extends StatefulWidget {
  final ProductLabel? existing;
  final Map<String, String>? template;

  const LabelEditorPage({
    super.key,
    this.existing,
    this.template,
  });

  @override
  State<LabelEditorPage> createState() => _LabelEditorPageState();
}

class _LabelEditorPageState extends State<LabelEditorPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _category;
  late final TextEditingController _quantity;
  late final TextEditingController _mrp;
  late final TextEditingController _salePrice;
  late final TextEditingController _batch;
  late final TextEditingController _manufacturer;
  late final TextEditingController _ingredients;
  late final TextEditingController _barcode;
  late final TextEditingController _qr;
  late final TextEditingController _customW;
  late final TextEditingController _customH;

  DateTime? _mfg;
  DateTime? _expiry;

  String _language = 'both';
  String _size = '3 x 2 inch';
  String _theme = 'Green';

  bool _showBarcode = true;
  bool _showQr = false;
  bool _showIngredients = true;
  bool _saving = false;

  static const Map<String, List<double>> sizes = {
    'Small sticker 1 x 1 inch': [1, 1],
    'Small 1.5 x 1 inch': [1.5, 1],
    '2 x 1 inch': [2, 1],
    '2 x 1.5 inch': [2, 1.5],
    '3 x 1 inch': [3, 1],
    '3 x 2 inch': [3, 2],
    '4 x 1 inch': [4, 1],
    '4 x 2 inch': [4, 2],
    '4 x 3 inch': [4, 3],
    '5 x 3 inch': [5, 3],
    '6 x 4 inch': [6, 4],
    'A4 sheet': [8.27, 11.69],
    'Round 1 inch': [1, 1],
    'Round 2 inch': [2, 2],
    'Custom size': [3, 2],
  };

  @override
  void initState() {
    super.initState();

    final e = widget.existing;
    final t = widget.template ?? {};

    _name = TextEditingController(
      text: e?.name ?? t['name'] ?? '',
    );
    _brand = TextEditingController(
      text: e?.brand ?? t['brand'] ?? '',
    );
    _category = TextEditingController(
      text: e?.category ?? t['category'] ?? '',
    );
    _quantity = TextEditingController(
      text: e?.quantity ?? '100 g',
    );
    _mrp = TextEditingController(text: e?.mrp ?? '');
    _salePrice = TextEditingController(
      text: e?.salePrice ?? '',
    );
    _batch = TextEditingController(text: e?.batch ?? '');
    _manufacturer = TextEditingController(
      text: e?.manufacturer ?? '',
    );
    _ingredients = TextEditingController(
      text: e?.ingredients ?? '',
    );
    _barcode = TextEditingController(
      text: e?.barcodeValue ?? '',
    );
    _qr = TextEditingController(text: e?.qrValue ?? '');
    _customW = TextEditingController(
      text: '${e?.customWidth ?? 3}',
    );
    _customH = TextEditingController(
      text: '${e?.customHeight ?? 2}',
    );

    _language = e?.language ?? 'both';
    _size = sizes.containsKey(e?.size)
        ? e!.size
        : (e?.size ?? '3 x 2 inch');

    if (!sizes.containsKey(_size)) {
      _size = '3 x 2 inch';
    }

    _theme = e?.theme ?? t['theme'] ?? 'Green';
    _mfg = _parseDate(e?.mfg);
    _expiry = _parseDate(e?.expiry);
    _showQr = (e?.qrValue ?? '').isNotEmpty;
    _showBarcode = true;
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;

    try {
      final p = s.split('/');
      return DateTime(
        int.parse(p[2]),
        int.parse(p[1]),
        int.parse(p[0]),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _category,
      _quantity,
      _mrp,
      _salePrice,
      _batch,
      _manufacturer,
      _ingredients,
      _barcode,
      _qr,
      _customW,
      _customH,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  String _dateText(DateTime? d) {
    if (d == null) return '';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _pickDate(bool manufacturing) async {
    final initial = manufacturing
        ? (_mfg ?? DateTime.now())
        : (_expiry ?? DateTime.now().add(
            const Duration(days: 365),
          ));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: manufacturing
          ? 'निर्माण तारीख चुनें'
          : 'एक्सपायरी तारीख चुनें',
    );

    if (picked != null) {
      setState(() {
        if (manufacturing) {
          _mfg = picked;
        } else {
          _expiry = picked;
        }
      });
    }
  }

  double _inches(String key, bool width) {
    if (key == 'Custom size') {
      return double.tryParse(
            width ? _customW.text : _customH.text,
          ) ??
          (width ? 3 : 2);
    }

    return sizes[key]?[width ? 0 : 1] ??
        (width ? 3 : 2);
  }

  Color get _accent => switch (_theme) {
    'Blue' => const Color(0xFF1E5AA8),
    'Red' => const Color(0xFFB3261E),
    'Black' => const Color(0xFF202124),
    'Purple' => const Color(0xFF7043A8),
    'Orange' => const Color(0xFFB45B12),
    _ => brandGreen,
  };

  ProductLabel _makeLabel() => ProductLabel(
    id: widget.existing?.id ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    name: _name.text.trim(),
    brand: _brand.text.trim(),
    category: _category.text.trim(),
    quantity: _quantity.text.trim(),
    mrp: _mrp.text.trim(),
    salePrice: _salePrice.text.trim(),
    batch: _batch.text.trim(),
    mfg: _dateText(_mfg),
    expiry: _dateText(_expiry),
    manufacturer: _manufacturer.text.trim(),
    ingredients: _ingredients.text.trim(),
    barcodeValue: _showBarcode ? _barcode.text.trim() : '',
    qrValue: _showQr ? _qr.text.trim() : '',
    language: _language,
    size: _size,
    customWidth: _inches(_size, true),
    customHeight: _inches(_size, false),
    theme: _theme,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_size == 'Custom size' &&
        (_inches(_size, true) <= 0 ||
            _inches(_size, false) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom size 0 से बड़ा रखें।'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final label = _makeLabel();
    final list = await LabelStore.load();
    final index = list.indexWhere((x) => x.id == label.id);

    if (index >= 0) {
      list[index] = label;
    } else {
      list.insert(0, label);
    }

    await LabelStore.save(list);

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('लेबल सेव हो गया।')),
    );

    Navigator.pop(context, true);
  }

  Future<Uint8List> _pdfBytes(ProductLabel label) async {
    final doc = pw.Document();

    final w = label.customWidth * PdfPageFormat.inch;
    final h = label.customHeight * PdfPageFormat.inch;

    final accent = switch (label.theme) {
      'Blue' => PdfColors.blue800,
      'Red' => PdfColors.red800,
      'Black' => PdfColors.grey900,
      'Purple' => PdfColors.purple800,
      'Orange' => PdfColors.orange800,
      _ => PdfColors.green800,
    };

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(w, h, marginAll: 7),
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(7),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: accent, width: 1.5),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  label.brand.isEmpty ? label.name : label.brand,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: accent,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  label.name,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: accent,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (label.category.isNotEmpty)
                pw.Text(
                  label.category,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              pw.Divider(color: accent),
              pw.Wrap(
                spacing: 8,
                runSpacing: 3,
                children: [
                  if (label.quantity.isNotEmpty)
                    pw.Text(
                      'Net Qty: ${label.quantity}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  if (label.mrp.isNotEmpty)
                    pw.Text(
                      'MRP: Rs. ${label.mrp}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  if (label.salePrice.isNotEmpty)
                    pw.Text(
                      'Sale: Rs. ${label.salePrice}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  if (label.batch.isNotEmpty)
                    pw.Text(
                      'Batch: ${label.batch}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  if (label.mfg.isNotEmpty)
                    pw.Text(
                      'Mfg: ${label.mfg}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  if (label.expiry.isNotEmpty)
                    pw.Text(
                      'Expiry: ${label.expiry}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                ],
              ),
              if (label.manufacturer.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                    label.manufacturer,
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                ),
              if (label.ingredients.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    'Ingredients: ${label.ingredients}',
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                ),
              if (label.barcodeValue.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: label.barcodeValue,
                    width: w * .45,
                    height: h * .12,
                  ),
                ),
              if (label.qrValue.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: label.qrValue,
                    width: h * .22,
                    height: h * .22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  Future<void> _print() async {
    if (!_formKey.currentState!.validate()) return;

    final label = _makeLabel();

    await Printing.layoutPdf(
      onLayout: (_) => _pdfBytes(label),
    );
  }

  Future<void> _sharePdf() async {
    if (!_formKey.currentState!.validate()) return;

    final bytes = await _pdfBytes(_makeLabel());

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: 'product_label.pdf',
        ),
      ],
      text: 'Product Label',
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    String? hint,
    int lines = 1,
    bool required = false,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: c,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? 'यह जानकारी जरूरी है'
              : null
          : null,
    );
  }

  Widget _dateField(
    String label,
    DateTime? date,
    bool manufacturing,
  ) =>
      InkWell(
        onTap: () => _pickDate(manufacturing),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_month),
          ),
          child: Text(
            date == null ? 'तारीख चुनें' : _dateText(date),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final custom = _size == 'Custom size';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Create Label' : 'Edit Label',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'डिजाइन और साइज',
              icon: Icons.palette_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(
                    labelText: 'Language / भाषा',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'both',
                      child: Text('हिंदी + English'),
                    ),
                    DropdownMenuItem(
                      value: 'hindi',
                      child: Text('हिंदी'),
                    ),
                    DropdownMenuItem(
                      value: 'english',
                      child: Text('English'),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () => _language = v ?? 'both',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _size,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'लेबल साइज',
                  ),
                  items: sizes.keys
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(
                    () => _size = v ?? '3 x 2 inch',
                  ),
                ),
                if (custom) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Width (inch)',
                          _customW,
                          keyboard:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          'Height (inch)',
                          _customH,
                          keyboard:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          required: true,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _theme,
                  decoration: const InputDecoration(
                    labelText: 'लेबल थीम',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Green',
                      child: Text('Green / हरा'),
                    ),
                    DropdownMenuItem(
                      value: 'Blue',
                      child: Text('Blue / नीला'),
                    ),
                    DropdownMenuItem(
                      value: 'Red',
                      child: Text('Red / लाल'),
                    ),
                    DropdownMenuItem(
                      value: 'Black',
                      child: Text('Black / काला'),
                    ),
                    DropdownMenuItem(
                      value: 'Purple',
                      child: Text('Purple / बैंगनी'),
                    ),
                    DropdownMenuItem(
                      value: 'Orange',
                      child: Text('Orange / नारंगी'),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () => _theme = v ?? 'Green',
                  ),
                ),
              ],
            ),
            _SectionCard(
              title: 'प्रोडक्ट विवरण',
              icon: Icons.inventory_2_outlined,
              children: [
                _field(
                  'प्रोडक्ट का नाम *',
                  _name,
                  hint: 'Herbal Hair Oil',
                  required: true,
                ),
                _field(
                  'ब्रांड / कंपनी का नाम',
                  _brand,
                  hint: 'ब्रांड नाम',
                ),
                _field(
                  'कैटेगरी / श्रेणी',
                  _category,
                  hint: 'Oil / Cosmetic / Herbal',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'नेट मात्रा',
                        _quantity,
                        hint: '100 ml',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        'MRP (₹)',
                        _mrp,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'सेल प्राइस (₹)',
                        _salePrice,
                        keyboard: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field('बैच नंबर', _batch),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        'निर्माण तारीख',
                        _mfg,
                        true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateField(
                        'एक्सपायरी तारीख',
                        _expiry,
                        false,
                      ),
                    ),
                  ],
                ),
                _field(
                  'निर्माता का नाम और पता',
                  _manufacturer,
                  lines: 2,
                ),
                _field(
                  'सामग्री / Ingredients',
                  _ingredients,
                  lines: 3,
                ),
              ],
            ),
                        _SectionCard(
              title: 'Barcode और QR Code',
              icon: Icons.qr_code_2,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Barcode दिखाएं'),
                  value: _showBarcode,
                  onChanged: (v) {
                    setState(() => _showBarcode = v);
                  },
                ),
                if (_showBarcode)
                  _field(
                    'Barcode / Product code',
                    _barcode,
                    hint: '8901234567890',
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('QR Code दिखाएं'),
                  value: _showQr,
                  onChanged: (v) {
                    setState(() => _showQr = v);
                  },
                ),
                if (_showQr)
                  _field(
                    'QR में क्या जानकारी रखें?',
                    _qr,
                    hint: 'Product details / website / contact',
                    lines: 2,
                  ),
              ],
            ),
            _SectionCard(
              title: 'लाइव प्रीव्यू',
              icon: Icons.visibility_outlined,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _accent,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _brand.text.isEmpty
                              ? 'YOUR BRAND'
                              : _brand.text,
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          _name.text.isEmpty
                              ? 'आपके प्रोडक्ट का नाम'
                              : _name.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      if (_category.text.isNotEmpty)
                        Center(child: Text(_category.text)),
                      const Divider(),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (_quantity.text.isNotEmpty)
                            Text('Net Qty: ${_quantity.text}'),
                          if (_mrp.text.isNotEmpty)
                            Text(
                              'MRP ₹${_mrp.text}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_salePrice.text.isNotEmpty)
                            Text('Sale ₹${_salePrice.text}'),
                          if (_batch.text.isNotEmpty)
                            Text('Batch: ${_batch.text}'),
                          if (_mfg != null)
                            Text('Mfg: ${_dateText(_mfg)}'),
                          if (_expiry != null)
                            Text('Expiry: ${_dateText(_expiry)}'),
                        ],
                      ),
                      if (_manufacturer.text.isNotEmpty)
                        Text(
                          _manufacturer.text,
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (_showBarcode && _barcode.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: _barcode.text,
                            width: 220,
                            height: 48,
                          ),
                        ),
                      if (_showQr && _qr.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: QrImageView(
                            data: _qr.text,
                            size: 85,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'साइज: $_size • '
                  '${_inches(_size, true)} × '
                  '${_inches(_size, false)} inch',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _saving ? 'सेव हो रहा है…' : 'लेबल सेव करें',
              ),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: _print,
              icon: const Icon(Icons.print_outlined),
              label: const Text('प्रिंट / Printer चुनें'),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: _sharePdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF शेयर / एक्सपोर्ट'),
            ),
            const SizedBox(height: 18),
            const Text(
              'प्रिंटिंग टिप: सामान्य A4 प्रिंटर और समर्थित '
              'Wi-Fi/Bluetooth प्रिंटर के लिए सिस्टम के प्रिंट '
              'डायलॉग का उपयोग करें। थर्मल प्रिंटर का पेपर '
              'साइज/ड्राइवर अलग हो सकता है।',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE0E8E5)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: brandGreen),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: w,
            ),
          ),
        ],
      ),
    ),
  );
}

class SavedLabelsPage extends StatefulWidget {
  const SavedLabelsPage({super.key});

  @override
  State<SavedLabelsPage> createState() => _SavedLabelsPageState();
}

class _SavedLabelsPageState extends State<SavedLabelsPage> {
  List<ProductLabel> _labels = [];
  String _query = '';
  bool _loading = true;

  Future<void> _load() async {
    final items = await LabelStore.load();

    if (!mounted) return;

    setState(() {
      _labels = items;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _delete(ProductLabel label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('लेबल हटाएं?'),
        content: Text('“${label.name}” को हटाना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('रद्द'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('हटाएं'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    _labels.removeWhere((x) => x.id == label.id);
    await LabelStore.save(_labels);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _labels.where((e) {
      return '${e.name} ${e.brand} ${e.category}'
          .toLowerCase()
          .contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Labels')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LabelEditorPage(),
            ),
          );

          if (result == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('नया लेबल'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'नाम, ब्रांड या कैटेगरी खोजें',
                    ),
                    onChanged: (v) {
                      setState(() => _query = v);
                    },
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 50,
                                color: Colors.black38,
                              ),
                              SizedBox(height: 10),
                              Text('अभी कोई सेव लेबल नहीं है'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            12, 0, 12, 80,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final label = filtered[i];

                            return Card(
                              color: Colors.white,
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE1F2EC),
                                  child: Icon(
                                    Icons.sell_outlined,
                                    color: brandGreen,
                                  ),
                                ),
                                title: Text(
                                  label.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${label.brand.isEmpty ? label.category : label.brand}'
                                  ' • ${label.size}\n'
                                  'MRP: ${label.mrp.isEmpty ? '—' : '₹${label.mrp}'}',
                                ),
                                isThreeLine: true,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LabelEditorPage(
                                        existing: label,
                                      ),
                                    ),
                                  );

                                  if (result == true) _load();
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LabelEditorPage(
                                            existing: label,
                                          ),
                                        ),
                                      );

                                      if (result == true) _load();
                                    } else if (v == 'copy') {
                                      final copy = ProductLabel.fromJson({
                                        ...label.toJson(),
                                        'id': DateTime.now()
                                            .microsecondsSinceEpoch
                                            .toString(),
                                        'name': '${label.name} (Copy)',
                                      });

                                      _labels.insert(0, copy);
                                      await LabelStore.save(_labels);

                                      if (mounted) setState(() {});
                                    } else if (v == 'delete') {
                                      _delete(label);
                                    } else if (v == 'print') {
                                      final doc = pw.Document();

                                      doc.addPage(
                                        pw.Page(
                                          pageFormat: PdfPageFormat(
                                            label.customWidth *
                                                PdfPageFormat.inch,
                                            label.customHeight *
                                                PdfPageFormat.inch,
                                            marginAll: 8,
                                          ),
                                          build: (_) => pw.Center(
                                            child: pw.Text(
                                              '${label.brand}\n'
                                              '${label.name}\n'
                                              'MRP: ${label.mrp}\n'
                                              'Qty: ${label.quantity}',
                                            ),
                                          ),
                                        ),
                                      );

                                      await Printing.layoutPdf(
                                        onLayout: (_) async => doc.save(),
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'copy',
                                      child: Text('कॉपी बनाएं'),
                                    ),
                                    PopupMenuItem(
                                      value: 'print',
                                      child: Text('प्रिंट'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('डिलीट'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  static const templates = [
    {
      'name': 'Herbal Green',
      'brand': '',
      'category': 'Herbal / Ayurvedic',
      'theme': 'Green',
    },
    {
      'name': 'Premium Blue',
      'brand': '',
      'category': 'Cosmetic / Personal Care',
      'theme': 'Blue',
    },
    {
      'name': 'Classic Black',
      'brand': '',
      'category': 'Premium Product',
      'theme': 'Black',
    },
    {
      'name': 'Red Highlight',
      'brand': '',
      'category': 'Special Edition',
      'theme': 'Red',
    },
    {
      'name': 'Natural Orange',
      'brand': '',
      'category': 'Food / Natural',
      'theme': 'Orange',
    },
    {
      'name': 'Royal Purple',
      'brand': '',
      'category': 'Premium Care',
      'theme': 'Purple',
    },
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ready Templates')),
    body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, i) {
        final t = templates[i];

        final color = switch (t['theme']) {
          'Blue' => Colors.blue,
          'Black' => Colors.black87,
          'Red' => Colors.red,
          'Orange' => Colors.orange,
          'Purple' => Colors.purple,
          _ => brandGreen,
        };

        return Card(
          color: Colors.white,
          child: ListTile(
            leading: Container(
              width: 54,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.sell_outlined, color: color),
            ),
            title: Text(
              t['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(t['category']!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LabelEditorPage(template: t),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class PrintHelpPage extends StatelessWidget {
  const PrintHelpPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Printer & Export')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _FeatureRow(
          icon: Icons.print,
          title: 'System Print Dialog',
          subtitle: 'प्रिंट बटन से उपलब्ध प्रिंटर चुनें',
        ),
        _FeatureRow(
          icon: Icons.picture_as_pdf,
          title: 'PDF Export',
          subtitle: 'PDF को सेव या शेयर किया जा सकता है',
        ),
        _FeatureRow(
          icon: Icons.wifi,
          title: 'Wi-Fi Printer',
          subtitle: 'फोन और प्रिंटर एक ही नेटवर्क पर हों',
        ),
        _FeatureRow(
          icon: Icons.bluetooth,
          title: 'Bluetooth / Thermal Printer',
          subtitle: 'समर्थन प्रिंटर और उसके ड्राइवर पर निर्भर करता है',
        ),
        SizedBox(height: 16),
        Text(
          'ध्यान दें: यह ऐप Flutter के सिस्टम प्रिंट डायलॉग का '
          'उपयोग करता है। हर Bluetooth thermal printer हर '
          'Android डिवाइस पर सीधे समर्थित नहीं होता; ऐसे '
          'प्रिंटर के लिए निर्माता का ऐप/SDK आवश्यक हो सकता है।',
        ),
      ],
    ),
  );
}
