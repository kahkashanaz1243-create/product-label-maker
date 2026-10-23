import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ProductLabelMakerApp());

class ProductLabelMakerApp extends StatelessWidget {
  const ProductLabelMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Label Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B55)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const LabelHomePage(),
    );
  }
}

class ProductLabel {
  ProductLabel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.mrp,
    required this.batch,
    required this.mfg,
    required this.exp,
    required this.manufacturer,
    required this.ingredients,
    required this.language,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String quantity;
  final String mrp;
  final String batch;
  final String mfg;
  final String exp;
  final String manufacturer;
  final String ingredients;
  final String language;
  final String updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'mrp': mrp,
        'batch': batch,
        'mfg': mfg,
        'exp': exp,
        'manufacturer': manufacturer,
        'ingredients': ingredients,
        'language': language,
        'updatedAt': updatedAt,
      };

  factory ProductLabel.fromJson(Map<String, dynamic> j) => ProductLabel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        category: j['category'] ?? '',
        quantity: j['quantity'] ?? '',
        mrp: j['mrp'] ?? '',
        batch: j['batch'] ?? '',
        mfg: j['mfg'] ?? '',
        exp: j['exp'] ?? '',
        manufacturer: j['manufacturer'] ?? '',
        ingredients: j['ingredients'] ?? '',
        language: j['language'] ?? 'both',
        updatedAt: j['updatedAt'] ?? '',
      );
}

class LabelHomePage extends StatefulWidget {
  const LabelHomePage({super.key});

  @override
  State<LabelHomePage> createState() => _LabelHomePageState();
}

class _LabelHomePageState extends State<LabelHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _previewKey = GlobalKey();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _quantity = TextEditingController(text: '100 g');
  final _mrp = TextEditingController();
  final _batch = TextEditingController();
  final _mfg = TextEditingController();
  final _exp = TextEditingController();
  final _manufacturer = TextEditingController();
  final _ingredients = TextEditingController();

  List<ProductLabel> _saved = [];
  String _language = 'both';
  String _labelSize = '3 × 2 inch';
  bool _loading = true;

  bool get _hindi => _language != 'english';
  bool get _english => _language != 'hindi';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _category, _quantity, _mrp, _batch, _mfg, _exp,
      _manufacturer, _ingredients
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('saved_labels') ?? [];
    setState(() {
      _saved = raw.map((s) => ProductLabel.fromJson(jsonDecode(s))).toList();
      _loading = false;
    });
  }

  ProductLabel _current() => ProductLabel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        category: _category.text.trim(),
        quantity: _quantity.text.trim(),
        mrp: _mrp.text.trim(),
        batch: _batch.text.trim(),
        mfg: _mfg.text.trim(),
        exp: _exp.text.trim(),
        manufacturer: _manufacturer.text.trim(),
        ingredients: _ingredients.text.trim(),
        language: _language,
        updatedAt: DateTime.now().toIso8601String(),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final label = _current();
    final prefs = await SharedPreferences.getInstance();
    _saved.insert(0, label);
    await prefs.setStringList(
      'saved_labels',
      _saved.map((e) => jsonEncode(e.toJson())).toList(),
    );
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_hindi ? 'लेबल मोबाइल में सेव हो गया।' : 'Label saved on this device.')),
      );
    }
  }

  void _loadLabel(ProductLabel p) {
    _name.text = p.name;
    _category.text = p.category;
    _quantity.text = p.quantity;
    _mrp.text = p.mrp;
    _batch.text = p.batch;
    _mfg.text = p.mfg;
    _exp.text = p.exp;
    _manufacturer.text = p.manufacturer;
    _ingredients.text = p.ingredients;
    setState(() => _language = p.language);
  }

  Future<void> _deleteLabel(ProductLabel p) async {
    _saved.removeWhere((e) => e.id == p.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_labels', _saved.map((e) => jsonEncode(e.toJson())).toList());
    setState(() {});
  }

  Future<void> _exportPng() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/product_label_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Product Label Maker');
    } catch (e) {
      _message('PNG export failed: $e');
    }
  }

  Future<void> _exportPdf() async {
    if (!_formKey.currentState!.validate()) return;
    final p = _current();
    final doc = pw.Document();
    final fields = <String, String>{
      if (p.name.isNotEmpty) 'Product / उत्पाद': p.name,
      if (p.category.isNotEmpty) 'Category / श्रेणी': p.category,
      if (p.quantity.isNotEmpty) 'Net Quantity / मात्रा': p.quantity,
      if (p.mrp.isNotEmpty) 'MRP': p.mrp,
      if (p.batch.isNotEmpty) 'Batch No. / बैच': p.batch,
      if (p.mfg.isNotEmpty) 'Mfg. Date / निर्माण': p.mfg,
      if (p.exp.isNotEmpty) 'Expiry / समाप्ति': p.exp,
      if (p.manufacturer.isNotEmpty) 'Manufactured by / निर्माता': p.manufacturer,
      if (p.ingredients.isNotEmpty) 'Ingredients / सामग्री': p.ingredients,
    };
    final dimensions = _labelSize == '2 × 1 inch'
        ? const [2.0, 1.0]
        : _labelSize == '4 × 2 inch'
            ? const [4.0, 2.0]
            : const [3.0, 2.0];
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(dimensions[0] * PdfPageFormat.inch, dimensions[1] * PdfPageFormat.inch, marginAll: 8),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.green800, width: 1.5),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        padding: const pw.EdgeInsets.all(7),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text(p.name.isEmpty ? 'PRODUCT NAME' : p.name,
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.green900))),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.green700),
            ...fields.entries.where((e) => e.key != 'Product / उत्पाद').map((e) =>
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('${e.key}: ${e.value}', style: const pw.TextStyle(fontSize: 7.5)),
              )),
          ],
        ),
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'product_label.pdf');
  }

  void _message(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Widget _field(String label, TextEditingController controller, {String? hint, int lines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: (_) => setState(() {}),
      validator: controller == _name
          ? (v) => (v == null || v.trim().isEmpty) ? (_hindi ? 'प्रोडक्ट का नाम भरें' : 'Enter product name') : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = _hindi;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Label Maker'),
        actions: [
          IconButton(
            tooltip: isHindi ? 'सेव किए लेबल' : 'Saved labels',
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: _showSaved,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(isHindi ? 'अपना प्रोडक्ट लेबल बनाएं' : 'Create your product label',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(isHindi ? 'ऑफलाइन काम करें • PDF/PNG में शेयर करें' : 'Work offline • Export and share as PDF/PNG'),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _language,
                    decoration: InputDecoration(labelText: isHindi ? 'भाषा / Language' : 'Language'),
                    items: const [
                      DropdownMenuItem(value: 'both', child: Text('हिंदी + English')),
                      DropdownMenuItem(value: 'hindi', child: Text('हिंदी')),
                      DropdownMenuItem(value: 'english', child: Text('English')),
                    ],
                    onChanged: (v) => setState(() => _language = v ?? 'both'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _labelSize,
                    decoration: InputDecoration(labelText: isHindi ? 'लेबल साइज' : 'Label size'),
                    items: const [
                      DropdownMenuItem(value: '2 × 1 inch', child: Text('2 × 1 inch')),
                      DropdownMenuItem(value: '3 × 2 inch', child: Text('3 × 2 inch')),
                      DropdownMenuItem(value: '4 × 2 inch', child: Text('4 × 2 inch')),
                    ],
                    onChanged: (v) => setState(() => _labelSize = v ?? '3 × 2 inch'),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(children: [
                      _field(isHindi ? 'प्रोडक्ट का नाम *' : 'Product name *', _name, hint: 'e.g. Herbal Hair Oil'),
                      const SizedBox(height: 10),
                      _field(isHindi ? 'कैटेगरी' : 'Category', _category, hint: 'Herbal / Food / Cosmetic'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _field(isHindi ? 'नेट मात्रा' : 'Net quantity', _quantity, hint: '100 ml')),
                        const SizedBox(width: 10),
                        Expanded(child: _field('MRP (₹)', _mrp, hint: '199')),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _field(isHindi ? 'बैच नंबर' : 'Batch no.', _batch)),
                        const SizedBox(width: 10),
                        Expanded(child: _field(isHindi ? 'निर्माण तिथि' : 'Mfg. date', _mfg, hint: 'MM/YYYY')),
                      ]),
                      const SizedBox(height: 10),
                      _field(isHindi ? 'एक्सपायरी / Best before' : 'Expiry / Best before', _exp),
                      const SizedBox(height: 10),
                      _field(isHindi ? 'निर्माता का नाम और पता' : 'Manufacturer name and address', _manufacturer, lines: 2),
                      const SizedBox(height: 10),
                      _field(isHindi ? 'सामग्री / Ingredients' : 'Ingredients', _ingredients, lines: 2),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text(isHindi ? 'लेबल प्रीव्यू' : 'Label preview', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  RepaintBoundary(
                    key: _previewKey,
                    child: _LabelPreview(
                      name: _name.text,
                      category: _category.text,
                      quantity: _quantity.text,
                      mrp: _mrp.text,
                      batch: _batch.text,
                      mfg: _mfg.text,
                      exp: _exp.text,
                      manufacturer: _manufacturer.text,
                      ingredients: _ingredients.text,
                      language: _language,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined),
                      label: Text(isHindi ? 'सेव करें' : 'Save')),
                    FilledButton.tonalIcon(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF')),
                    OutlinedButton.icon(onPressed: _exportPng, icon: const Icon(Icons.image_outlined),
                      label: const Text('PNG')),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    isHindi
                      ? 'ध्यान दें: यह सामान्य लेबल डिजाइन टूल है। उत्पाद की श्रेणी के अनुसार कानूनी घोषणाएं और नियम अलग हो सकते हैं।'
                      : 'Note: This is a general label design tool. Legal declarations vary by product category.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }

  void _showSaved() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .7,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_hindi ? 'सेव किए गए लेबल' : 'Saved labels',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: _saved.isEmpty
                  ? Center(child: Text(_hindi ? 'अभी कोई लेबल सेव नहीं है' : 'No saved labels yet'))
                  : ListView.builder(
                      itemCount: _saved.length,
                      itemBuilder: (_, i) {
                        final p = _saved[i];
                        return ListTile(
                          leading: const Icon(Icons.label_outline),
                          title: Text(p.name),
                          subtitle: Text('${p.quantity} • ${p.mrp.isEmpty ? 'MRP —' : '₹${p.mrp}'}'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _loadLabel(p);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await _deleteLabel(p);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _showSaved();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LabelPreview extends StatelessWidget {
  const _LabelPreview({
    required this.name,
    required this.category,
    required this.quantity,
    required this.mrp,
    required this.batch,
    required this.mfg,
    required this.exp,
    required this.manufacturer,
    required this.ingredients,
    required this.language,
  });

  final String name, category, quantity, mrp, batch, mfg, exp, manufacturer, ingredients, language;

  @override
  Widget build(BuildContext context) {
    final showHi = language != 'english';
    final showEn = language != 'hindi';
    final labelText = <String>[
      if (category.trim().isNotEmpty) category.trim(),
      if (quantity.trim().isNotEmpty) '${showHi ? 'मात्रा' : ''}${showHi && showEn ? ' / ' : ''}${showEn ? 'Net Qty' : ''}: $quantity',
      if (mrp.trim().isNotEmpty) 'MRP: ₹$mrp',
      if (batch.trim().isNotEmpty) '${showHi ? 'बैच' : ''}${showHi && showEn ? ' / ' : ''}${showEn ? 'Batch' : ''}: $batch',
      if (mfg.trim().isNotEmpty) '${showHi ? 'निर्माण' : ''}${showHi && showEn ? ' / ' : ''}${showEn ? 'Mfg.' : ''}: $mfg',
      if (exp.trim().isNotEmpty) '${showHi ? 'समाप्ति' : ''}${showHi && showEn ? ' / ' : ''}${showEn ? 'Expiry' : ''}: $exp',
      if (manufacturer.trim().isNotEmpty) manufacturer.trim(),
      if (ingredients.trim().isNotEmpty) '${showHi ? 'सामग्री' : ''}${showHi && showEn ? ' / ' : ''}${showEn ? 'Ingredients' : ''}: $ingredients',
    ];
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF176B55), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Text(name.trim().isEmpty ? 'PRODUCT NAME' : name.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF176B55))),
        ),
        const Divider(color: Color(0xFF176B55)),
        if (labelText.isEmpty)
          const Text('Add product details to preview your label.', style: TextStyle(color: Colors.black54))
        else
          ...labelText.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(s, style: const TextStyle(fontSize: 11, color: Colors.black87)),
              )),
      ]),
    );
  }
}
