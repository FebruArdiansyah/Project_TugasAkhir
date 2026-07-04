import 'dart:typed_data';

class PickedAttachment {
  final Uint8List bytes;
  final String fileName;

  const PickedAttachment({
    required this.bytes,
    required this.fileName,
  });
}