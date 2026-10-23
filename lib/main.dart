
import 'dart:convert';
import 'dart:io';
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
  WidgetsFlutterBinding.ensureInitialized();
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
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      quantity: (json['quantity'] ?? '').toString(),
      mrp: (json['mrp'] ?? '').toString(),
      batch: (json['batch'] ?? '').toString(),
      mfg: (json['mfg'] ?? '').toString(),
      expiry: (json['expiry'] ?? '').toString(),
      manufacturer: (json['manufacturer'] ?? '').toString(),
      ingredients: (json['ingredients'] ?? '').toString(),
      language: (json['language'] ?? 'both').toString(),
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

  List<TextEditingController> get _controllers => [
        _name,
        _category,
        _quantity,
        _mrp,
        _batch,
        _mfg,
        _expiry,
        _manufacturer,
        _ingredients,
      ];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_refreshPreview);
    }
    _loadSaved();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_refreshPreview);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = prefs.getStringList('product_labels') ?? [];
      final labels = <ProductLabel>[];

      for (final record in records) {
        try {
          labels.add(
            ProductLabel.fromJson(
              jsonDecode(record) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          // Ignore corrupted records.
        }
      }

      if (!mounted) return;
      setState(() {
        _saved = labels;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Load error: $error');
    }
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

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'product_labels',
      _saved.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _saveLabel() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final label = _currentLabel();
    final index = _saved.indexWhere(
      (item) => item.id == label.id,
    );

    _saved.insert(0, label);

    try {
      await _persist();
      if (!mounted) return;
      setState(() {});
      _message(_hindi ? 'लेबल सेव हो गया।' : 'Label saved.');
    } catch (error) {
      _saved.remove(label);
      _message('Save error: $error');
    }
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

    setState(() => _language = label.language);
  }

  Future<void> _deleteLabel(ProductLabel label) async {
    _saved.removeWhere((item) => item.id == label.id);
    await _persist();
    if (mounted) setState(() {});
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _field(
    String title,
    TextEditingController controller, {
    int lines = 1,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboardType,
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

  Future<void> _exportPng() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await WidgetsBinding.instance.endOfFrame;

      final object = _previewKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) {
        _message(_hindi ? 'प्रीव्यू तैयार नहीं है।' : 'Preview not ready.');
        return;
      }

      final image = await object.toImage(pixelRatio: 3);
      try {
        final data = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null) {
          _message('Could not create PNG.');
          return;
        }

        final directory = await getTemporaryDirectory();
        final file = File(
          '${directory.path}/product_label_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/png')],
          text: 'Product Label Maker',
        );
      } finally {
        image.dispose();
      }
    } catch (error) {
      _message('PNG export error: $error');
    }
  }

  Future<void> _exportPdf() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
    final height = parts.length > 1
        ? double.tryParse(parts[1].replaceAll(' inch', '')) ?? 2
        : 2;

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

    try {
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'product_label.pdf',
      );
    } catch (error) {
      _message('PDF export error: $error');
    }
  }

  void _showSavedLabels() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _hindi ? 'सेव किए गए लेबल' : 'Saved Labels',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _saved.isEmpty
                      ? Center(
                          child: Text(
                            _hindi
                                ? 'अभी कोई लेबल सेव नहीं है।'
                                : 'No saved labels yet.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _saved.length,
                          itemBuilder: (context, index) {
                            final label = _saved[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.label_outline),
                              ),
                              title: Text(label.name),
                              subtitle: Text(
                                '${label.category} • ${label.quantity}',
                              ),
                              onTap: () {
                                _loadLabel(label);
                                Navigator.pop(sheetContext);
                              },
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirmed =
                                      await showDialog<bool>(
                                    context: sheetContext,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text(
                                        _hindi
                                            ? 'लेबल हटाएँ?'
                                            : 'Delete label?',
                                      ),
                                      content: Text(
                                        _hindi
                                            ? 'यह सेव किया गया लेबल हट जाएगा।'
                                            : 'This saved label will be deleted.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: Text(
                                            _hindi ? 'रद्द करें' : 'Cancel',
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          child: Text(
                                            _hindi ? 'हटाएँ' : 'Delete',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await _deleteLabel(label);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
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
                              child: _field(
                                'MRP (₹)',
                                _mrp,
                                hint: '199',
                                keyboardType: TextInputType.number,
                              ),
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
                        ? 'नोट: प्रोडक्ट की श्रेणी के अनुसार जरूरी घोषणाएँ अलग हो सकती हैं। छापने से पहले जानकारी जाँचें।'
                        : 'Note: Required declarations vary by product category. Verify information before printing.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }
}

class _LabelPreview extends StatelessWidget {
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

  const _LabelPreview({
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

  bool get _hindi => language != 'english';

  @override
  Widget build(BuildContext context) {
    final title = name.trim().isEmpty
        ? (_hindi ? 'आपके प्रोडक्ट का नाम' : 'Your Product Name')
        : name.trim();

    Widget detail(String label, String value) {
      if (value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          '$label: ${value.trim()}',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF263238),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFF176B55),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF176B55),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF176B55)),
          if (category.trim().isNotEmpty)
            detail(_hindi ? 'श्रेणी / Category' : 'Category', category),
          if (quantity.trim().isNotEmpty)
            detail(_hindi ? 'नेट मात्रा / Net Qty.' : 'Net Quantity', quantity),
          if (mrp.trim().isNotEmpty) detail('MRP (₹)', mrp),
          if (batch.trim().isNotEmpty)
            detail(_hindi ? 'बैच नंबर' : 'Batch No.', batch),
          if (mfg.trim().isNotEmpty)
            detail(_hindi ? 'निर्माण तिथि' : 'Mfg. Date', mfg),
          if (expiry.trim().isNotEmpty)
            detail(_hindi ? 'एक्सपायरी' : 'Expiry', expiry),
          if (manufacturer.trim().isNotEmpty)
            detail(_hindi ? 'निर्माता' : 'Manufacturer', manufacturer),
          if (ingredients.trim().isNotEmpty)
            detail(_hindi ? 'सामग्री' : 'Ingredients', ingredients),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Product Label Maker',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
