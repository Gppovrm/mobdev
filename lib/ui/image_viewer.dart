import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class ImageViewer extends StatefulWidget {
  final String url;
  final VoidCallback onClose;

  const ImageViewer({super.key, required this.url, required this.onClose});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.closeImage,
          onPressed: widget.onClose,
        ),
      ),
      body: SafeArea(
        child: InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.network(
              widget.url,
              key: ValueKey(_attempt),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const CircularProgressIndicator(),
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.imageError,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      PaintingBinding.instance.imageCache.evict(
                        NetworkImage(widget.url),
                      );
                      setState(() => _attempt++);
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
