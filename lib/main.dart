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
          _FeatureRow(
            icon: Icons.calendar_month_outlined,
            title: 'तारीख चुनें',
            subtitle: 'निर्माण और एक्सपायरी के लिए कैलेंडर',
            onTap: () => _open(const LabelEditorPage()),
          ),
          _FeatureRow(
            icon: Icons.qr_code_2,
            title: 'Barcode / QR',
            subtitle: 'उत्पाद कोड और QR डेटा जोड़ें',
            onTap: () => _open(const LabelEditorPage()),
          ),
          _FeatureRow(
            icon: Icons.straighten,
            title: 'Custom Size',
            subtitle: 'अपनी चौड़ाई और ऊंचाई सेट करें',
            onTap: () => _open(
              const LabelEditorPage(initialSize: 'Custom size'),
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
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
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: brandGreen),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
class LabelEditorPage extends StatefulWidget {
  final String initialSize;

  const LabelEditorPage({
    super.key,
    this.initialSize = '3 x 2 inch',
  });

  @override
  State<LabelEditorPage> createState() => _LabelEditorPageState();
}

class _LabelEditorPageState extends State<LabelEditorPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _category = TextEditingController();
  final _quantity = TextEditingController();
  final _mrp = TextEditingController();
  final _salePrice = TextEditingController();
  final _batch = TextEditingController();
  final _mfg = TextEditingController();
  final _expiry = TextEditingController();
  final _manufacturer = TextEditingController();
  final _ingredients = TextEditingController();
  final _barcode = TextEditingController();
  final _qr = TextEditingController();
  final _width = TextEditingController(text: '3');
  final _height = TextEditingController(text: '2');

  String _size = '3 x 2 inch';
  String _theme = 'Green';
  String _language = 'both';
  ProductLabel? _editing;

  @override
  void initState() {
    super.initState();
    _size = widget.initialSize;
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
      _mfg,
      _expiry,
      _manufacturer,
      _ingredients,
      _barcode,
      _qr,
      _width,
      _height,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(
    TextEditingController controller,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      controller.text =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
      setState(() {});
    }
  }

  Widget _field(
    String label,
    TextEditingController c, {
    String? hint,
    int lines = 1,
    bool required = false,
    TextInputType? keyboard,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: c,
      maxLines: lines,
      keyboardType: keyboard,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) {
                return 'यह जानकारी जरूरी है';
              }
              return null;
            }
          : null,
    );
  }

  ProductLabel _makeLabel() {
    return ProductLabel(
      id: _editing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      category: _category.text.trim(),
      quantity: _quantity.text.trim(),
      mrp: _mrp.text.trim(),
      salePrice: _salePrice.text.trim(),
      batch: _batch.text.trim(),
      mfg: _mfg.text.trim(),
      expiry: _expiry.text.trim(),
      manufacturer: _manufacturer.text.trim(),
      ingredients: _ingredients.text.trim(),
      barcodeValue: _barcode.text.trim(),
      qrValue: _qr.text.trim(),
      language: _language,
      size: _size,
      customWidth: double.tryParse(_width.text) ?? 3,
      customHeight: double.tryParse(_height.text) ?? 2,
      theme: _theme,
    );
  }

  Future<void> _saveLabel() async {
    if (!_formKey.currentState!.validate()) return;

    final label = _makeLabel();
    final labels = await LabelStore.load();

    final index = labels.indexWhere((e) => e.id == label.id);

    if (index >= 0) {
      labels[index] = label;
    } else {
      labels.insert(0, label);
    }

    await LabelStore.save(labels);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('लेबल सेव हो गया')),
    );
  }

  Future<void> _openPrint() async {
    if (!_formKey.currentState!.validate()) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LabelPreviewPage(label: _makeLabel()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Product Label'),
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: _openPrint,
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                        'नेट मात्रा / वजन',
                        _quantity,
                        hint: '100 g / 100 ml',
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
                      child: _field(
                        'निर्माण तारीख',
                        _mfg,
                        hint: 'तारीख चुनें',
                        readOnly: true,
                        onTap: () => _pickDate(_mfg),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        'एक्सपायरी तारीख',
                        _expiry,
                        hint: 'तारीख चुनें',
                        readOnly: true,
                        onTap: () => _pickDate(_expiry),
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
            const SizedBox(height: 14),
            _SectionCard(
              title: 'डिजाइन और साइज',
              icon: Icons.palette_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _size,
                  decoration: const InputDecoration(
                    labelText: 'लेबल साइज',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '3 x 2 inch',
                      child: Text('3 x 2 inch'),
                    ),
                    DropdownMenuItem(
                      value: '2 x 1 inch',
                      child: Text('2 x 1 inch'),
                    ),
                    DropdownMenuItem(
                      value: '4 x 3 inch',
                      child: Text('4 x 3 inch'),
                    ),
                    DropdownMenuItem(
                      value: 'Custom size',
                      child: Text('Custom size'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _size = v);
                  },
                ),
                if (_size == 'Custom size')
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'चौड़ाई (inch)',
                          _width,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          'ऊंचाई (inch)',
                          _height,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                DropdownButtonFormField<String>(
                  value: _theme,
                  decoration: const InputDecoration(
                    labelText: 'लेबल कलर',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Green',
                      child: Text('Green'),
                    ),
                    DropdownMenuItem(
                      value: 'Blue',
                      child: Text('Blue'),
                    ),
                    DropdownMenuItem(
                      value: 'Red',
                      child: Text('Red'),
                    ),
                    DropdownMenuItem(
                      value: 'Black',
                      child: Text('Black'),
                    ),
                    DropdownMenuItem(
                      value: 'Gold',
                      child: Text('Gold'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _theme = v);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(
                    labelText: 'भाषा',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'both',
                      child: Text('Hindi + English'),
                    ),
                    DropdownMenuItem(
                      value: 'hindi',
                      child: Text('Hindi'),
                    ),
                    DropdownMenuItem(
                      value: 'english',
                      child: Text('English'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _language = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Barcode और QR Code',
              icon: Icons.qr_code_2,
              children: [
                _field(
                  'Barcode Value',
                  _barcode,
                  hint: 'उदाहरण: 8901234567890',
                ),
                _field(
                  'QR Code Data',
                  _qr,
                  hint: 'वेबसाइट या उत्पाद जानकारी',
                ),
              ],
            ),
            const SizedBox(height: 14),
            LabelPreviewCard(label: _makeLabel()),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saveLabel,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Label'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _openPrint,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Preview / PDF / Print'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF245D9C),
                minimumSize: const Size.fromHeight(52),
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
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children.expand(
              (child) => [
                child,
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LabelPreviewCard extends StatelessWidget {
  final ProductLabel label;

  const LabelPreviewCard({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _labelColor(label.theme);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Preview',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label.brand.isNotEmpty)
                    Text(
                      label.brand,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    label.name.isEmpty
                        ? 'Product Name'
                        : label.name,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (label.category.isNotEmpty)
                    Text(label.category),
                  const Divider(),
                  if (label.quantity.isNotEmpty)
                    Text('Net Qty: ${label.quantity}'),
                  if (label.mrp.isNotEmpty)
                    Text('MRP: ₹${label.mrp}'),
                  if (label.salePrice.isNotEmpty)
                    Text('Price: ₹${label.salePrice}'),
                  if (label.batch.isNotEmpty)
                    Text('Batch No: ${label.batch}'),
                  if (label.mfg.isNotEmpty)
                    Text('Mfg: ${label.mfg}'),
                  if (label.expiry.isNotEmpty)
                    Text('Expiry: ${label.expiry}'),
                  if (label.manufacturer.isNotEmpty)
                    Text(label.manufacturer),
                  if (label.ingredients.isNotEmpty)
                    Text('Ingredients: ${label.ingredients}'),
                  if (label.barcodeValue.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: label.barcodeValue,
                      width: 220,
                      height: 55,
                      drawText: true,
                    ),
                  ],
                  if (label.qrValue.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: QrImageView(
                        data: label.qrValue,
                        version: QrVersions.auto,
                        size: 85,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _labelColor(String theme) {
  switch (theme) {
    case 'Blue':
      return Colors.blue.shade800;
    case 'Red':
      return Colors.red.shade800;
    case 'Black':
      return Colors.black;
    case 'Gold':
      return const Color(0xFFAA801E);
    default:
      return brandGreen;
  }
}

class LabelPreviewPage extends StatelessWidget {
  final ProductLabel label;

  const LabelPreviewPage({super.key, required this.label});

  Future<Uint8List> _makePdf() async {
    final pdf = pw.Document();

    final width = label.size == 'Custom size'
        ? (label.customWidth * PdfPageFormat.inch)
        : label.size == '2 x 1 inch'
            ? 2 * PdfPageFormat.inch
            : label.size == '4 x 3 inch'
                ? 4 * PdfPageFormat.inch
                : 3 * PdfPageFormat.inch;

    final height = label.size == 'Custom size'
        ? (label.customHeight * PdfPageFormat.inch)
        : label.size == '2 x 1 inch'
            ? 1 * PdfPageFormat.inch
            : label.size == '4 x 3 inch'
                ? 3 * PdfPageFormat.inch
                : 2 * PdfPageFormat.inch;

    final format = PdfPageFormat(
      width,
      height,
      marginAll: 8,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.green800,
                width: 1.5,
              ),
            ),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                if (label.brand.isNotEmpty)
                  pw.Text(
                    label.brand,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.Text(
                  label.name,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (label.category.isNotEmpty)
                  pw.Text(label.category),
                pw.Divider(),
                if (label.quantity.isNotEmpty)
                  pw.Text('Net Qty: ${label.quantity}'),
                if (label.mrp.isNotEmpty)
                  pw.Text('MRP: Rs. ${label.mrp}'),
                if (label.salePrice.isNotEmpty)
                  pw.Text('Price: Rs. ${label.salePrice}'),
                if (label.batch.isNotEmpty)
                  pw.Text('Batch: ${label.batch}'),
                if (label.mfg.isNotEmpty)
                  pw.Text('Mfg: ${label.mfg}'),
                if (label.expiry.isNotEmpty)
                  pw.Text('Expiry: ${label.expiry}'),
                if (label.manufacturer.isNotEmpty)
                  pw.Text(label.manufacturer),
                if (label.ingredients.isNotEmpty)
                  pw.Text('Ingredients: ${label.ingredients}'),
                if (label.barcodeValue.isNotEmpty)
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: label.barcodeValue,
                    width: 150,
                    height: 35,
                  ),
                if (label.qrValue.isNotEmpty)
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: label.qrValue,
                    width: 45,
                    height: 45,
                  ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _print(BuildContext context) async {
    final bytes = await _makePdf();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _share(BuildContext context) async {
    final bytes = await _makePdf();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'product_label.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Preview'),
        actions: [
          IconButton(
            tooltip: 'Share PDF',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LabelPreviewCard(label: label),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _print(context),
            icon: const Icon(Icons.print),
            label: const Text('Print Label'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export / Share PDF'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedLabelsPage extends StatefulWidget {
  const SavedLabelsPage({super.key});

  @override
  State<SavedLabelsPage> createState() => _SavedLabelsPageState();
}

class _SavedLabelsPageState extends State<SavedLabelsPage> {
  List<ProductLabel> _labels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final labels = await LabelStore.load();
    if (!mounted) return;

    setState(() {
      _labels = labels;
      _loading = false;
    });
  }

  Future<void> _delete(ProductLabel label) async {
    _labels.removeWhere((e) => e.id == label.id);
    await LabelStore.save(_labels);
    if (mounted) setState(() {});
  }

  Future<void> _edit(ProductLabel label) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LabelEditorPageForEdit(label: label),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Saved Labels')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _labels.isEmpty
              ? const Center(
                  child: Text('अभी कोई लेबल सेव नहीं है'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _labels.length,
                  itemBuilder: (context, index) {
                    final label = _labels[index];

                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: const Icon(
                          Icons.sell_outlined,
                          color: brandGreen,
                        ),
                        title: Text(label.name),
                        subtitle: Text(
                          '${label.brand} • ${label.quantity}',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LabelPreviewPage(label: label),
                            ),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _edit(label);
                            } else if (value == 'delete') {
                              _delete(label);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class LabelEditorPageForEdit extends StatefulWidget {
  final ProductLabel label;

  const LabelEditorPageForEdit({
    super.key,
    required this.label,
  });

  @override
  State<LabelEditorPageForEdit> createState() =>
      _LabelEditorPageForEditState();
}

class _LabelEditorPageForEditState
    extends State<LabelEditorPageForEdit> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Label')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'लेबल एडिट करने के लिए नीचे Create Label खोलें।',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LabelEditorPage(),
                  ),
                );
              },
              child: const Text('Open Label Editor'),
            ),
          ],
        ),
      ),
    );
  }
}

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = [
      ('Green Herbal', 'Green', 'Herbal Product'),
      ('Premium Gold', 'Gold', 'Premium Product'),
      ('Classic Blue', 'Blue', 'General Product'),
      ('Bold Red', 'Red', 'Special Product'),
      ('Simple Black', 'Black', 'Minimal Product'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Label Templates')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final t = templates[index];

          return Card(
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _labelColor(t.$2),
                child: const Icon(
                  Icons.sell_outlined,
                  color: Colors.white,
                ),
              ),
              title: Text(t.$1),
              subtitle: Text(t.$3),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LabelEditorPageWithTheme(
                      theme: t.$2,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class LabelEditorPageWithTheme extends StatelessWidget {
  final String theme;

  const LabelEditorPageWithTheme({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Template')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const LabelEditorPage(),
              ),
            );
          },
          child: const Text('Create Label with Template'),
        ),
      ),
    );
  }
}

class PrintHelpPage extends StatelessWidget {
  const PrintHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Print & Export Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf, color: brandGreen),
              title: Text('PDF Export'),
              subtitle: Text(
                'लेबल का PDF बनाकर शेयर या सेव करें।',
              ),
            ),
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.print, color: brandGreen),
              title: Text('Direct Printing'),
              subtitle: Text(
                'Print Label विकल्प से उपलब्ध प्रिंटर चुनें।',
              ),
            ),
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.straighten, color: brandGreen),
              title: Text('Label Size'),
              subtitle: Text(
                'प्रिंट करते समय लेबल का साइज और स्केल जांचें।',
              ),
            ),
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.qr_code, color: brandGreen),
              title: Text('Barcode / QR'),
              subtitle: Text(
                'Barcode और QR के लिए सही डेटा भरें।',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
