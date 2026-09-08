/// İçe / dışa aktarım formatları — aynı üçlü kurgu.
enum KasaTransferFormat { jpg, pdf, excel }

extension KasaTransferFormatX on KasaTransferFormat {
  String get label => switch (this) {
        KasaTransferFormat.jpg => 'JPG',
        KasaTransferFormat.pdf => 'PDF',
        KasaTransferFormat.excel => 'Excel',
      };

  String get successExport => switch (this) {
        KasaTransferFormat.jpg => 'JPG dışa aktarıldı.',
        KasaTransferFormat.pdf => 'PDF dışa aktarıldı.',
        KasaTransferFormat.excel => 'Excel dışa aktarıldı.',
      };
}
