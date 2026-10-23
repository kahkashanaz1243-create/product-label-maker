import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
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
    const green = Color(0xFF126B56);

    return MaterialApp(
      title: 'Product Label Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF5F8F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F8F6),
          foregroundColor: Color(0xFF17372F),
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFD9E4DE),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: green,
              width: 1.7,
            ),
          ),
        ),
      ),
      home: const LabelHomePage(),
    );
  }
}

class ProductLabel {
  final String id, name, brand, category, quantity, mrp, salePrice, batch;
  final String mfg, expiry, manufacturer, address, ingredients, usage;
  final String warnings, customerCare, barcode, language, size, color;
  final bool showQr, showBarcode;

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
    required this.address,
    required this.ingredients,
    required this.usage,
    required this.warnings,
    required this.customerCare,
    required this.barcode,
    required this.language,
    required this.size,
    required this.color,
    required this.showQr,
    required this.showBarcode,
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
        'address': address,
        'ingredients': ingredients,
        'usage': usage,
        'warnings': warnings,
        'customerCare': customerCare,
        'barcode': barcode,
        'language': language,
        'size': size,
        'color': color,
        'showQr': showQr,
        'showBarcode': showBarcode,
      };

  factory ProductLabel.fromJson(Map<String, dynamic> j) {
    return ProductLabel(
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
      address: '${j['address'] ?? ''}',
      ingredients: '${j['ingredients'] ?? ''}',
      usage: '${j['usage'] ?? ''}',
      warnings: '${j['warnings'] ?? ''}',
      customerCare: '${j['customerCare'] ?? ''}',
      barcode: '${j['barcode'] ?? ''}',
      language: '${j['language'] ?? 'both'}',
      size: '${j['size'] ?? '3 x 2 inch'}',
      color: '${j['color'] ?? 'green'}',
      showQr: j['showQr'] == true,
      showBarcode: j['showBarcode'] == true,
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

  final Map<String, TextEditingController> c = {
    'name': TextEditingController(),
    'brand': TextEditingController(),
    'category': TextEditingController(),
    'quantity': TextEditingController(text: '100 g'),
    'mrp': TextEditingController(),
    'salePrice': TextEditingController(),
    'batch': TextEditingController(),
    'mfg': TextEditingController(),
    'expiry': TextEditingController(),
    'manufacturer': TextEditingController(),
    'address': TextEditingController(),
    'ingredients': TextEditingController(),
    'usage': TextEditingController(),
    'warnings': TextEditingController(),
    'customerCare': TextEditingController(),
    'barcode': TextEditingController(),
  };

  List<ProductLabel> saved = [];
  String language = 'both';
  String size = '3 x 2 inch';
  String labelColor = 'green';

  bool showQr = true;
  bool showBarcode = true;
  bool loading = true;

  bool get hindi => language != 'english';

  @override
  void initState() {
    super.initState();

    for (final controller in c.values) {
      controller.addListener(() {
        if (mounted) setState(() {});
      });
    }

    _loadSaved();
  }

  @override
  void dispose() {
    for (final controller in c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String v(String key) => c[key]!.text.trim();

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('product_labels_v2') ?? [];

    if (!mounted) return;

    setState(() {
      saved = list
          .map(
            (e) => ProductLabel.fromJson(
              jsonDecode(e) as Map<String, dynamic>,
            ),
          )
          .toList();
      loading = false;
    });
  }

  ProductLabel _current() {
    return ProductLabel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: v('name'),
      brand: v('brand'),
      category: v('category'),
      quantity: v('quantity'),
      mrp: v('mrp'),
      salePrice: v('salePrice'),
      batch: v('batch'),
      mfg: v('mfg'),
      expiry: v('expiry'),
      manufacturer: v('manufacturer'),
      address: v('address'),
      ingredients: v('ingredients'),
      usage: v('usage'),
      warnings: v('warnings'),
      customerCare: v('customerCare'),
      barcode: v('barcode').isEmpty ? v('name') : v('barcode'),
      language: language,
      size: size,
      color: labelColor,
      showQr: showQr,
      showBarcode: showBarcode,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    saved.insert(0, _current());

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'product_labels_v2',
      saved.map((e) => jsonEncode(e.toJson())).toList(),
    );

    if (mounted) {
      setState(() {});
      _msg(
        hindi
            ? 'लेबल फोन में सेव हो गया।'
            : 'Label saved on this phone.',
      );
    }
  }

  void _load(ProductLabel p) {
    final values = <String, String>{
      'name': p.name,
      'brand': p.brand,
      'category': p.category,
      'quantity': p.quantity,
      'mrp': p.mrp,
      'salePrice': p.salePrice,
      'batch': p.batch,
      'mfg': p.mfg,
      'expiry': p.expiry,
      'manufacturer': p.manufacturer,
      'address': p.address,
      'ingredients': p.ingredients,
      'usage': p.usage,
      'warnings': p.warnings,
      'customerCare': p.customerCare,
      'barcode': p.barcode,
    };

    for (final e in values.entries) {
      c[e.key]!.text = e.value;
    }

    setState(() {
      language = p.language;
      size = p.size;
      labelColor = p.color;
      showQr = p.showQr;
      showBarcode = p.showBarcode;
    });

    Navigator.pop(context);
  }

  Future<void> _delete(ProductLabel p) async {
    saved.removeWhere((e) => e.id == p.id);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'product_labels_v2',
      saved.map((e) => jsonEncode(e.toJson())).toList(),
    );

    if (mounted) setState(() {});
  }

  void _msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _pickDate(String key) async {
    DateTime initial = DateTime.now();

    final current = v(key);
    final parsed = DateTime.tryParse(current);

    if (parsed != null) initial = parsed;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: hindi ? 'तारीख चुनें' : 'Select date',
    );

    if (picked != null) {
      c[key]!.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    }
  }

  Future<void> _exportPng() async {
    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        _msg('Preview is not ready.');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3);

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        image.dispose();
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/product_label_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Product Label Maker',
      );

      image.dispose();
    } catch (e) {
      _msg('PNG export failed: $e');
    }
  }

  PdfPageFormat _pageFormat() {
    final bits = size.split(' x ');
    final w = double.tryParse(bits.first) ?? 3;
    final h =
        double.tryParse(bits[1].replaceAll(' inch', '')) ?? 2;

    return PdfPageFormat(
      w * PdfPageFormat.inch,
      h * PdfPageFormat.inch,
      marginAll: 5,
    );
  }

  Future<Uint8List> _makePdf() async {
    final p = _current();
    final doc = pw.Document();

    final accent = p.color == 'blue'
        ? PdfColors.blue800
        : p.color == 'red'
            ? PdfColors.red800
            : p.color == 'black'
                ? PdfColors.grey900
                : PdfColors.green800;

    final items = <String>[
      if (p.category.isNotEmpty) 'Category / श्रेणी: ${p.category}',
      if (p.quantity.isNotEmpty) 'Net Quantity / मात्रा: ${p.quantity}',
      if (p.mrp.isNotEmpty) 'MRP: Rs. ${p.mrp}',
      if (p.salePrice.isNotEmpty) 'Sale Price: Rs. ${p.salePrice}',
      if (p.batch.isNotEmpty) 'Batch No.: ${p.batch}',
      if (p.mfg.isNotEmpty) 'Mfg. Date: ${p.mfg}',
      if (p.expiry.isNotEmpty) 'Expiry / Best Before: ${p.expiry}',
      if (p.manufacturer.isNotEmpty)
        'Manufacturer: ${p.manufacturer}',
      if (p.address.isNotEmpty) p.address,
      if (p.ingredients.isNotEmpty)
        'Ingredients: ${p.ingredients}',
      if (p.usage.isNotEmpty) 'How to Use: ${p.usage}',
      if (p.warnings.isNotEmpty) 'Caution: ${p.warnings}',
      if (p.customerCare.isNotEmpty)
        'Customer Care: ${p.customerCare}',
    ];

    doc.addPage(
      pw.Page(
        pageFormat: _pageFormat(),
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(7),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: accent, width: 1.4),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (p.brand.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    p.brand,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: accent,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              pw.Center(
                child: pw.Text(
                  p.name,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: accent,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Divider(color: accent),
              ...items.map(
                (t) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(
                    t,
                    style: const pw.TextStyle(fontSize: 7.2),
                  ),
                ),
              ),
              if (p.showBarcode && p.barcode.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: p.barcode.length > 80
                      ? p.barcode.substring(0, 80)
                      : p.barcode,
                  width: 100,
                  height: 25,
                ),
              ],
              if (p.showQr && p.barcode.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: p.barcode.length > 500
                      ? p.barcode.substring(0, 500)
                      : p.barcode,
                  width: 35,
                  height: 35,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  Future<void> _exportPdf() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final bytes = await _makePdf();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'product_label.pdf',
      );
    } catch (e) {
      _msg('PDF export failed: $e');
    }
  }

  Future<void> _printLabel() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final bytes = await _makePdf();

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'product_label.pdf',
        format: _pageFormat(),
      );
    } catch (e) {
      _msg(
        hindi
            ? 'प्रिंटर उपलब्ध नहीं है या प्रिंटिंग में समस्या हुई: $e'
            : 'Printer unavailable or printing failed: $e',
      );
    }
  }

  Widget _field(
    String key,
    String title, {
    String? hint,
    int lines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: c[key],
      maxLines: lines,
      decoration: InputDecoration(
        labelText: title,
        hintText: hint,
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return hindi
                    ? 'यह जानकारी जरूरी है'
                    : 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _dateField(String key, String title) {
    return TextFormField(
      controller: c[key],
      readOnly: true,
      onTap: () => _pickDate(key),
      decoration: InputDecoration(
        labelText: title,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () => _pickDate(key),
        ),
      ),
    );
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
            tooltip: 'Saved labels',
            onPressed: _showSaved,
            icon: const Icon(Icons.folder_open_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F755C),
                          Color(0xFF37A889),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sell_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Professional Product Labels',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Offline • PDF / PNG • Print • Barcode / QR',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    'Design & Language',
                    Icons.palette_outlined,
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: language,
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
                          onChanged: (x) {
                            setState(() => language = x ?? 'both');
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: size,
                          decoration: InputDecoration(
                            labelText:
                                hindi ? 'लेबल साइज' : 'Label size',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '2 x 1 inch',
                              child: Text('2 × 1 inch'),
                            ),
                            DropdownMenuItem(
                              value: '3 x 2 inch',
                              child: Text('3 × 2 inch'),
                            ),
                            DropdownMenuItem(
                              value: '4 x 2 inch',
                              child: Text('4 × 2 inch'),
                            ),
                          ],
                          onChanged: (x) {
                            setState(() => size = x ?? '3 x 2 inch');
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: labelColor,
                          decoration: InputDecoration(
                            labelText:
                                hindi ? 'लेबल थीम' : 'Label theme',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'green',
                              child: Text('Green / हरा'),
                            ),
                            DropdownMenuItem(
                              value: 'blue',
                              child: Text('Blue / नीला'),
                            ),
                            DropdownMenuItem(
                              value: 'red',
                              child: Text('Red / लाल'),
                            ),
                            DropdownMenuItem(
                              value: 'black',
                              child: Text('Black / काला'),
                            ),
                          ],
                          onChanged: (x) {
                            setState(() => labelColor = x ?? 'green');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _section(
                          'Product Details',
                          Icons.inventory_2_outlined,
                          Column(
                            children: [
                              _field(
                                'name',
                                hindi
                                    ? 'प्रोडक्ट का नाम *'
                                    : 'Product name *',
                                hint: 'Herbal Hair Oil',
                                required: true,
                              ),
                              const SizedBox(height: 10),
                              _field(
                                'brand',
                                hindi
                                    ? 'ब्रांड / कंपनी का नाम'
                                    : 'Brand / company name',
                              ),
                              const SizedBox(height: 10),
                              _field(
                                'category',
                                hindi
                                    ? 'कैटेगरी / श्रेणी'
                                    : 'Category',
                                hint: 'Food / Cosmetic / Herbal / Clothing',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _field(
                                      'quantity',
                                      hindi ? 'नेट मात्रा' : 'Net quantity',
                                      hint: '100 ml',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _field(
                                      'mrp',
                                      'MRP (₹)',
                                      hint: '199',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _field(
                                      'salePrice',
                                      hindi
                                          ? 'सेल प्राइस (₹)'
                                          : 'Sale price (₹)',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _field(
                                      'batch',
                                      hindi ? 'बैच नंबर' : 'Batch number',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _dateField(
                                      'mfg',
                                      hindi
                                          ? 'निर्माण तारीख'
                                          : 'Mfg. date',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _dateField(
                                      'expiry',
                                      hindi
                                          ? 'एक्सपायरी तारीख'
                                          : 'Expiry date',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _section(
                          'Manufacturer & Instructions',
                          Icons.factory_outlined,
                          Column(
                            children: [
                              _field(
                                'manufacturer',
                                hindi
                                    ? 'निर्माता का नाम'
                                    : 'Manufacturer name',
                              ),
                              const SizedBox(height: 10),
                              _field(
                                'address',
                                hindi ? 'पूरा पता' : 'Full address',
                                lines: 2,
                              ),
                              const SizedBox(height: 10),
                              _field(
                                'ingredients',
                                hindi
                                    ? 'सामग्री / Ingredients'
                                    : 'Ingredients',
                                lines: 2,
                              ),
                              const SizedBox(height: 10),
                              _field(
                                'usage',
                                hindi
                                    ? 'उपयोग करने का तरीका'
                                    : 'How to use',
                                lines: 2,
                              ),
                              const SizedBox(height: 10),
                              _field(
                                'warnings',
                                hindi
                                    ? 'चेतावनी / सावधानियां'
                                    : 'Warnings / caution',
                                lines: 2,
                              ),
                              const SizedBox(height: 10),
                              _field(
                                'customerCare',
                                hindi
                                    ? 'कस्टमर केयर / फोन / वेबसाइट'
                                    : 'Customer care / phone / website',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _section(
                          'Barcode & QR Code',
                          Icons.qr_code_2,
                          Column(
                            children: [
                              _field(
                                'barcode',
                                hindi
                                    ? 'बारकोड / QR में डालने वाला टेक्स्ट'
                                    : 'Text / SKU / URL for barcode & QR',
                                hint: 'SKU12345 or https://example.com',
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  hindi
                                      ? 'QR कोड दिखाएं'
                                      : 'Show QR code',
                                ),
                                value: showQr,
                                onChanged: (x) {
                                  setState(() => showQr = x);
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  hindi
                                      ? 'बारकोड दिखाएं (Code 128)'
                                      : 'Show barcode (Code 128)',
                                ),
                                value: showBarcode,
                                onChanged: (x) {
                                  setState(() => showBarcode = x);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    hindi ? 'लेबल प्रीव्यू' : 'Label Preview',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RepaintBoundary(
                    key: _previewKey,
                    child: _Preview(
                      name: v('name'),
                      brand: v('brand'),
                      category: v('category'),
                      quantity: v('quantity'),
                      mrp: v('mrp'),
                      salePrice: v('salePrice'),
                      batch: v('batch'),
                      mfg: v('mfg'),
                      expiry: v('expiry'),
                      manufacturer: v('manufacturer'),
                      address: v('address'),
                      ingredients: v('ingredients'),
                      usage: v('usage'),
                      warnings: v('warnings'),
                      customerCare: v('customerCare'),
                      barcode:
                          v('barcode').isEmpty ? v('name') : v('barcode'),
                      showQr: showQr,
                      showBarcode: showBarcode,
                      colorName: labelColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(hindi ? 'सेव करें' : 'Save'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _exportPng,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('PNG'),
                      ),
                      FilledButton.icon(
                        onPressed: _printLabel,
                        icon: const Icon(Icons.print_outlined),
                        label: Text(hindi ? 'प्रिंट करें' : 'Print'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hindi
                        ? 'प्रिंट के लिए फोन/टैबलेट में प्रिंटर सेवा या संगत प्रिंटर उपलब्ध होना चाहिए। कानूनी लेबलिंग नियम उत्पाद श्रेणी के अनुसार जांचें।'
                        : 'Printing requires a compatible printer or print service. Check applicable product-label regulations for your product category.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE3EBE6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF126B56)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  void _showSaved() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  hindi ? 'सेव किए गए लेबल' : 'Saved Labels',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: saved.isEmpty
                    ? Center(
                        child: Text(
                          hindi
                              ? 'अभी कोई लेबल सेव नहीं है।'
                              : 'No saved labels yet.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: saved.length,
                        itemBuilder: (_, i) {
                          final p = saved[i];

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.sell_outlined),
                            ),
                            title: Text(
                              p.name.isEmpty ? 'Untitled label' : p.name,
                            ),
                            subtitle: Text(
                              '${p.quantity} • MRP ₹${p.mrp}',
                            ),
                            onTap: () => _load(p),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _delete(p),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final String name, brand, category, quantity, mrp, salePrice, batch, mfg, expiry;
  final String manufacturer, address, ingredients, usage, warnings, customerCare;
  final String barcode, colorName;
  final bool showQr, showBarcode;

  const _Preview({
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
    required this.address,
    required this.ingredients,
    required this.usage,
    required this.warnings,
    required this.customerCare,
    required this.barcode,
    required this.showQr,
    required this.showBarcode,
    required this.colorName,
  });

  Color get accent => colorName == 'blue'
      ? Colors.blue.shade800
      : colorName == 'red'
          ? Colors.red.shade800
          : colorName == 'black'
              ? Colors.black87
              : const Color(0xFF126B56);

  @override
  Widget build(BuildContext context) {
    final rows = <String>[
      if (category.isNotEmpty) 'Category: $category',
      if (quantity.isNotEmpty) 'Net Qty: $quantity',
      if (mrp.isNotEmpty) 'MRP: ₹$mrp',
      if (salePrice.isNotEmpty) 'Sale Price: ₹$salePrice',
      if (batch.isNotEmpty) 'Batch: $batch',
      if (mfg.isNotEmpty) 'Mfg: $mfg',
      if (expiry.isNotEmpty) 'Expiry: $expiry',
      if (manufacturer.isNotEmpty) 'Mfr: $manufacturer',
      if (address.isNotEmpty) address,
      if (ingredients.isNotEmpty) 'Ingredients: $ingredients',
      if (usage.isNotEmpty) 'Use: $usage',
      if (warnings.isNotEmpty) 'Caution: $warnings',
      if (customerCare.isNotEmpty) 'Care: $customerCare',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: accent, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (brand.isNotEmpty)
            Center(
              child: Text(
                brand.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          Center(
            child: Text(
              name.isEmpty ? 'YOUR PRODUCT NAME' : name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(),
          ...rows.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(s, style: const TextStyle(fontSize: 12)),
            ),
          ),
          if (showBarcode && barcode.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: barcode.length > 80
                    ? barcode.substring(0, 80)
                    : barcode,
                width: 210,
                height: 48,
                drawText: true,
              ),
            ),
          ],
          if (showQr && barcode.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: barcode.length > 500
                    ? barcode.substring(0, 500)
                    : barcode,
                width: 90,
                height: 90,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
