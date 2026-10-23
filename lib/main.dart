
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

void main() {
  runApp(const ProductLabelMakerApp());
}

class ProductLabelMakerApp extends StatelessWidget {
  const ProductLabelMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Label Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B55),
        ),
        useMaterial3: true,
      ),
      home: const LabelHomePage(),
    );
  }
}

class ProductLabel {
  final String id;
  final String name;
  final String category;
  final String quantity;
  final String mrp;
  final String batch;
  final String mfg;
  final String expiry;
  final String manufacturer;
  final String ingredients;
  final String language;

  const ProductLabel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.mrp,
    required this.batch,
    required this.mfg,
    required this.expiry,
    required this.manufacturer,
    required this.ingredients,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'mrp': mrp,
        'batch': batch,
        'mfg': mfg,
        'expiry': expiry,
        'manufacturer': manufacturer,
        'ingredients': ingredients,
        'language': language,
      };

  factory ProductLabel.fromJson(Map<String, dynamic> json) {
    return ProductLabel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? '',
      mrp: json['mrp'] ?? '',
      batch: json['batch'] ?? '',
      mfg: json['mfg'] ?? '',
      expiry: json['expiry'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      ingredients: json['ingredients'] ?? '',
      language: json['language'] ?? 'both',
    );
  }
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
  final _expiry = TextEditingController();
  final _manufacturer = TextEditingController();
  final _ingredients = TextEditingController();

  List<ProductLabel> _saved = [];
  String _language = 'both';
  String _size = '3 x 2 inch';
  bool _loading = true;

  bool get _hindi => _language != 'english';

  @override
  void initState() {
    super.initState();
    _loadSaved();

    for (final controller in [
      _name,
      _category,
      _quantity,
      _mrp,
      _batch,
      _mfg,
      _expiry,
      _manufacturer,
      _ingredients,
    ]) {
      controller.addListener(_refreshPreview);
    }
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _category,
      _quantity,
      _mrp,
      _batch,
      _mfg,
      _expiry,
      _manufacturer,
      _ingredients,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('product_labels') ?? [];

    if (!mounted) return;

    setState(() {
      _saved = items.map((item) {
        return ProductLabel.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        );
      }).toList();
      _loading = false;
    });
  }

  ProductLabel _currentLabel() {
    return ProductLabel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      category: _category.text.trim(),
      quantity: _quantity.text.trim(),
      mrp: _mrp.text.trim(),
      batch: _batch.text.trim(),
      mfg: _mfg.text.trim(),
      expiry: _expiry.text.trim(),
      manufacturer: _manufacturer.text.trim(),
      ingredients: _ingredients.text.trim(),
      language: _language,
    );
  }

  Future<void> _saveLabel() async {
    if (!_formKey.currentState!.validate()) return;

    final label = _currentLabel();
    final prefs = await SharedPreferences.getInstance();

    _saved.insert(0, label);
    await prefs.setStringList(
      'product_labels',
      _saved.map((item) => jsonEncode(item.toJson())).toList(),
    );

    if (!mounted) return;

    setState(() {});
    _message(_hindi ? 'लेबल सेव हो गया।' : 'Label saved.');
  }

  void _loadLabel(ProductLabel label) {
    _name.text = label.name;
    _category.text = label.category;
    _quantity.text = label.quantity;
    _mrp.text = label.mrp;
    _batch.text = label.batch;
    _mfg.text = label.mfg;
    _expiry.text = label.expiry;
    _manufacturer.text = label.manufacturer;
    _ingredients.text = label.ingredients;

    setState(() {
      _language = label.language;
    });
  }

  Future<void> _deleteLabel(ProductLabel label) async {
    _saved.removeWhere((item) => item.id == label.id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'product_labels',
      _saved.map((item) => jsonEncode(item.toJson())).toList(),
    );

    if (mounted) setState(() {});
  }

  Future<void> _exportPng() async {
    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        _message(_hindi ? 'प्रीव्यू तैयार नहीं है।' : 'Preview not ready.');
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (data == null) return;

      final Uint8List bytes = data.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/product_label_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Product Label Maker',
      );
    } catch (error) {
      _message('PNG export error: $error');
    }
  }

  Future<void> _exportPdf() async {
    if (!_formKey.currentState!.validate()) return;

    final label = _currentLabel();
    final document = pw.Document();

    final details = <String>[
      if (label.category.isNotEmpty) 'Category: ${label.category}',
      if (label.quantity.isNotEmpty) 'Net Quantity: ${label.quantity}',
      if (label.mrp.isNotEmpty) 'MRP: Rs. ${label.mrp}',
      if (label.batch.isNotEmpty) 'Batch No.: ${label.batch}',
      if (label.mfg.isNotEmpty) 'Mfg. Date: ${label.mfg}',
      if (label.expiry.isNotEmpty) 'Expiry: ${label.expiry}',
      if (label.manufacturer.isNotEmpty)
        'Manufacturer: ${label.manufacturer}',
      if (label.ingredients.isNotEmpty)
        'Ingredients: ${label.ingredients}',
    ];

    final parts = _size.split(' x ');
    final width = double.tryParse(parts[0]) ?? 3;
    final height = double.tryParse(
          parts[1].replaceAll(' inch', ''),
        ) ??
        2;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          width * PdfPageFormat.inch,
          height * PdfPageFormat.inch,
          marginAll: 8,
        ),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.green800,
                width: 1.5,
              ),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    label.name,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Divider(color: PdfColors.green700),
                ...details.map(
                  (detail) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      detail,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'product_label.pdf',
    );
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _field(
    String title,
    TextEditingController controller, {
    int lines = 1,
    String? hint,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: title,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return _hindi
                    ? 'यह जानकारी भरना जरूरी है'
                    : 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hindi = _hindi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Label Maker'),
        actions: [
          IconButton(
            tooltip: hindi ? 'मेरे लेबल' : 'My Labels',
            onPressed: _showSavedLabels,
            icon: const Icon(Icons.folder_open),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hindi
                                ? 'अपने प्रोडक्ट का लेबल बनाएं'
                                : 'Create your product label',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hindi
                                ? 'ऑफलाइन सेव करें • PDF और PNG में शेयर करें'
                                : 'Save offline • Export PDF and PNG',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _language,
                    decoration: const InputDecoration(
                      labelText: 'Language / भाषा',
                      border: OutlineInputBorder(),
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
                    onChanged: (value) {
                      setState(() => _language = value ?? 'both');
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _size,
                    decoration: InputDecoration(
                      labelText: hindi ? 'लेबल साइज' : 'Label size',
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '2 x 1 inch',
                        child: Text('2 x 1 inch'),
                      ),
                      DropdownMenuItem(
                        value: '3 x 2 inch',
                        child: Text('3 x 2 inch'),
                      ),
                      DropdownMenuItem(
                        value: '4 x 2 inch',
                        child: Text('4 x 2 inch'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _size = value ?? '3 x 2 inch');
                    },
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _field(
                          hindi ? 'प्रोडक्ट का नाम *' : 'Product name *',
                          _name,
                          hint: 'Herbal Hair Oil',
                          required: true,
                        ),
                        const SizedBox(height: 10),
                        _field(
                          hindi ? 'कैटेगरी' : 'Category',
                          _category,
                          hint: 'Food / Cosmetic / Herbal',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                hindi ? 'नेट मात्रा' : 'Net quantity',
                                _quantity,
                                hint: '100 ml',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _field('MRP (₹)', _mrp, hint: '199'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                hindi ? 'बैच नंबर' : 'Batch number',
                                _batch,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _field(
                                hindi ? 'निर्माण तिथि' : 'Mfg. date',
                                _mfg,
                                hint: 'MM/YYYY',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _field(
                          hindi
                              ? 'एक्सपायरी / Best before'
                              : 'Expiry / Best before',
                          _expiry,
                        ),
                        const SizedBox(height: 10),
                        _field(
                          hindi
                              ? 'निर्माता का नाम और पता'
                              : 'Manufacturer name and address',
                          _manufacturer,
                          lines: 2,
                        ),
                        const SizedBox(height: 10),
                        _field(
                          hindi ? 'सामग्री / Ingredients' : 'Ingredients',
                          _ingredients,
                          lines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    hindi ? 'लेबल प्रीव्यू' : 'Label Preview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                      expiry: _expiry.text,
                      manufacturer: _manufacturer.text,
                      ingredients: _ingredients.text,
                      language: _language,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _saveLabel,
                        icon: const Icon(Icons.save),
                        label: Text(hindi ? 'सेव करें' : 'Save'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _exportPng,
                        icon: const Icon(Icons.image),
                        label: const Text('PNG'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    hindi
                        ? 'नोट: उत्पाद की श्रेणी के अनुसार लागू नियम और घोषणाएँ अलग हो सकती हैं।'
                        : 'Note: Required legal declarations vary by product category.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }

  void _showSavedLabels() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _hindi ? 'सेव किए गए लेबल' : 'Saved Labels',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                    
