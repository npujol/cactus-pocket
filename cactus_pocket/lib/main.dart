import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/cactus_inference.dart';
import 'services/image_rgb.dart';
import 'services/model_store.dart';

void main() => runApp(const MirageApp());

class MirageApp extends StatelessWidget {
  const MirageApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mirage',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xff101113),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffb8f36b),
            brightness: Brightness.dark,
          ),
        ),
        home: const MirageHomePage(),
      );
}

enum _ModelStatus { absent, downloading, verifying, ready, failed }

class MirageHomePage extends StatefulWidget {
  const MirageHomePage({super.key});

  @override
  State<MirageHomePage> createState() => _MirageHomePageState();
}

class _MirageHomePageState extends State<MirageHomePage> {
  final _store = ModelStore();
  final _inference = CactusInference();
  final _picker = ImagePicker();

  _ModelStatus _modelStatus = _ModelStatus.absent;
  bool _busy = false;
  double? _downloadProgress;
  File? _selectedFile;
  String? _description;
  String? _rawJson;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshModelStatus();
  }

  Future<void> _refreshModelStatus() async {
    try {
      final ready = await _store.isReady();
      if (ready) {
        final file = await _store.modelFile;
        await _loadModel(file);
      } else {
        if (mounted) setState(() => _modelStatus = _ModelStatus.absent);
      }
    } catch (error) {
      if (mounted) {
        setState(() { _modelStatus = _ModelStatus.failed; _error = '$error'; });
      }
    }
  }

  Future<void> _downloadModel() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _modelStatus = _ModelStatus.downloading;
      _error = null;
      _downloadProgress = 0;
    });
    try {
      final download = _store.download(onProgress: (value) {
        if (mounted) setState(() => _downloadProgress = value);
      });
      final file = await download;
      if (!mounted) return;
      setState(() => _modelStatus = _ModelStatus.verifying);
      await _loadModel(file);
    } catch (error) {
      if (mounted) {
        setState(() { _modelStatus = _ModelStatus.failed; _error = '$error'; });
      }
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  Future<void> _cancelDownload() async {
    await _store.cancel();
    if (mounted) setState(() { _modelStatus = _ModelStatus.absent; _busy = false; _downloadProgress = null; });
  }

  Future<void> _loadModel(File file) async {
    setState(() { _busy = true; _modelStatus = _ModelStatus.verifying; _error = null; });
    try {
      final bytes = await file.readAsBytes();
      await _inference.loadModel(bytes);
      if (mounted) setState(() => _modelStatus = _ModelStatus.ready);
    } catch (error) {
      if (mounted) setState(() { _modelStatus = _ModelStatus.failed; _error = '$error'; });
      rethrow;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    if (_busy) return;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final file = File(picked.path);
      // Decode now to reject unsupported/corrupt images before showing a preview.
      decodeToRgb(await file.readAsBytes());
      if (mounted) {
        setState(() { _selectedFile = file; _description = null; _rawJson = null; _error = null; });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not open this image: $error');
    }
  }

  Future<void> _describeImage() async {
    final file = _selectedFile;
    if (file == null || _busy || _modelStatus != _ModelStatus.ready) return;
    setState(() { _busy = true; _error = null; _description = null; });
    try {
      final decoded = decodeToRgb(await file.readAsBytes());
      final raw = await _inference.describe(rgb: decoded.bytes, width: decoded.width, height: decoded.height);
      final result = jsonDecode(raw) as Map<String, dynamic>;
      final scene = result['scene'];
      final reasoning = result['reasoning'];
      final description = scene is Map ? [scene['background'], scene['style']].whereType<String>().join(' · ') : '';
      if (mounted) {
        setState(() {
          _rawJson = const JsonEncoder.withIndent('  ').convert(result);
          _description = description.isNotEmpty ? description : (reasoning is String ? reasoning : 'Mirage returned a result.');
        });
      }
    } on CactusInferenceException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = 'Mirage returned invalid JSON: ${error.message}');
    } catch (error) {
      if (mounted) setState(() => _error = 'Inference failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelReady = _modelStatus == _ModelStatus.ready;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          children: [
            Row(children: [
              const Icon(Icons.blur_on_rounded, color: Color(0xffb8f36b), size: 28),
              const SizedBox(width: 10),
              const Expanded(child: Text('MIRAGE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2.5))),
              _statusChip,
            ]),
            const SizedBox(height: 20),
            _sectionTitle('MODEL'),
            const SizedBox(height: 8),
            _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.memory, color: Color(0xffb8f36b)),
                const SizedBox(width: 10),
                Expanded(child: Text(modelReady ? 'Mirage model ready · stored on this device' : _statusText, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (_modelStatus == _ModelStatus.absent || _modelStatus == _ModelStatus.failed)
                  FilledButton.tonal(onPressed: _busy ? null : _downloadModel, child: const Text('Get model')),
                if (_modelStatus == _ModelStatus.downloading)
                  TextButton(onPressed: _cancelDownload, child: const Text('Cancel')),
              ]),
              if (_modelStatus == _ModelStatus.downloading) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 4),
                Text(_downloadProgress == null ? 'Connecting…' : '${(_downloadProgress! * 100).round()}%', style: const TextStyle(color: Colors.white60)),
              ],
            ])),
            const SizedBox(height: 22),
            _sectionTitle('IMAGE'),
            const SizedBox(height: 8),
            _panel(child: Column(children: [
              if (_selectedFile != null)
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedFile!, height: 210, width: double.infinity, fit: BoxFit.contain))
              else
                Container(height: 170, width: double.infinity, decoration: BoxDecoration(color: const Color(0xff191a1c), borderRadius: BorderRadius.circular(12)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 34, color: Colors.white54), SizedBox(height: 8), Text('Choose an image to describe', style: TextStyle(color: Colors.white54))])),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : _pickImage, icon: const Icon(Icons.upload_file), label: const Text('Choose image'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(onPressed: modelReady && _selectedFile != null && !_busy ? _describeImage : null, icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(_busy ? 'Working…' : 'Describe'))),
              ]),
            ])),
            const SizedBox(height: 22),
            _sectionTitle('DESCRIPTION'),
            const SizedBox(height: 8),
            _panel(child: Text(_description ?? 'Your image description will appear here.', style: TextStyle(fontSize: 15, height: 1.5, color: _description == null ? Colors.white38 : Colors.white))),
            if (_rawJson != null) ...[
              const SizedBox(height: 12),
              ExpansionTile(title: const Text('Raw response JSON'), tilePadding: EdgeInsets.zero, children: [Align(alignment: Alignment.centerLeft, child: SelectableText(_rawJson!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)))]),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              _panel(color: const Color(0xff351d1d), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline, color: Color(0xffff8585)), const SizedBox(width: 10), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xffffc4c4))))])),
            ],
            const SizedBox(height: 24),
            const Text('Inference runs locally. Network is used only to download the model.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String get _statusText => switch (_modelStatus) {
        _ModelStatus.absent => 'Model not downloaded',
        _ModelStatus.downloading => 'Downloading pinned model…',
        _ModelStatus.verifying => 'Verifying and loading model…',
        _ModelStatus.ready => 'Mirage model ready',
        _ModelStatus.failed => 'Model setup failed',
      };

  Widget get _statusChip {
    final color = _modelStatus == _ModelStatus.ready ? const Color(0xffb8f36b) : Colors.white38;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(_modelStatus == _ModelStatus.ready ? 'LOCAL' : 'SETUP', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)));
  }

  Widget _sectionTitle(String value) => Text(value, style: const TextStyle(color: Color(0xffb8f36b), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8));

  Widget _panel({required Widget child, Color? color}) => Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color ?? const Color(0xff202124), borderRadius: BorderRadius.circular(16)), child: child);
}
