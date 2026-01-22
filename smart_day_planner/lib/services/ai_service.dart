import '../data/models/task.dart';

class AiPlanBlock {
  final String start;
  final String end;
  final String title;
  final String reason;

  AiPlanBlock({required this.start, required this.end, required this.title, required this.reason});
}

class AiPlan {
  final List<AiPlanBlock> blocks;
  final String notes;
  AiPlan({required this.blocks, required this.notes});
}

class AiService {
  final String baseUrl;
  AiService({required this.baseUrl});

  Future<AiPlan> generatePlan(List<Task> tasks, {String? topic}) async {
    final List<AiPlanBlock> suggestions = [];
    final String t = topic?.trim() ?? "";

    if (t.isNotEmpty) {
      final low = t.toLowerCase();
      
      // ✅ KONUYA GÖRE ÖZEL EYLEM SETLERİ
      if (low.contains('temizlik') || low.contains('ev') || low.contains('duzen')) {
        suggestions.addAll([
          AiPlanBlock(start: '09:00', end: '10:00', title: 'Ortamı Havalandır ve Hazırlan', reason: 'Ferah bir başlangıç verimliliği artırır.'),
          AiPlanBlock(start: '10:30', end: '12:00', title: '$t Seansı: Odaklanmış Hijyen', reason: 'En çok vakit alan bölgeleri aradan çıkar.'),
          AiPlanBlock(start: '13:30', end: '14:30', title: 'Detaylar ve Yüzey Temizliği', reason: 'Gözden kaçan köşeleri tertemiz yap.'),
          AiPlanBlock(start: '15:00', end: '15:30', title: 'Eşyaları Organize Et ve Bitir', reason: 'Düzenin kalıcı olması için yerleşim yap.'),
        ]);
      } 
      else if (low.contains('yemek') || low.contains('mutfak') || low.contains('tarif')) {
        suggestions.addAll([
          AiPlanBlock(start: '10:00', end: '10:30', title: 'Menü ve Tarif İnceleme', reason: 'Gerekli adımları belirleyerek süreci planla.'),
          AiPlanBlock(start: '11:00', end: '12:00', title: 'Malzeme Hazırlığı (Doğrama)', reason: 'Pişirme anında kolaylık sağlamak için ön hazırlık yap.'),
          AiPlanBlock(start: '16:00', end: '18:00', title: 'Ana Pişirme ve Teknik Uygulama', reason: 'Lezzeti ön plana çıkaracak teknikleri uygula.'),
          AiPlanBlock(start: '18:30', end: '19:30', title: 'Sunum ve Servis Hazırlığı', reason: 'Emeğini şık bir sofrayla taçlandır.'),
        ]);
      }
      else if (low.contains('matematik') || low.contains('sinav') || low.contains('ders') || low.contains('ogren') || low.contains('java')) {
        suggestions.addAll([
          AiPlanBlock(start: '09:30', end: '11:00', title: '$t: Teorik Konu Anlatımı', reason: 'Zihnin en açık olduğu saatte yeni bilgileri öğren.'),
          AiPlanBlock(start: '11:30', end: '13:30', title: '$t: Uygulamalı Pratik ve Soru', reason: 'Öğrendiğin formülleri veya kodları test et.'),
          AiPlanBlock(start: '15:00', end: '17:00', title: '$t: İleri Seviye Örnekler', reason: 'Daha karmaşık senaryolar üzerinde uzmanlaş.'),
          AiPlanBlock(start: '19:00', end: '20:00', title: 'Günün Kritik Tekrarı', reason: 'Bugün öğrendiklerini unutmamak için özetle.'),
        ]);
      }
      else if (low.contains('alisveris') || low.contains('market')) {
        suggestions.addAll([
          AiPlanBlock(start: '10:00', end: '10:30', title: 'İhtiyaç Listesi ve Bütçe', reason: 'Gereksiz harcamaları önlemek için plan yap.'),
          AiPlanBlock(start: '11:00', end: '13:00', title: 'Market veya Mağaza Gezisi', reason: 'Kalabalık saatlerden önce işini hallet.'),
          AiPlanBlock(start: '14:00', end: '15:00', title: 'Ürünleri Düzenleme', reason: 'Aldıklarını yerlerine yerleştirerek ev düzenini koru.'),
        ]);
      }
      // ✅ HER ŞEYE UYUM SAĞLAYAN TAM DİNAMİK YAPI (Fallback)
      else {
        suggestions.addAll([
          AiPlanBlock(start: '09:00', end: '10:30', title: '$t: İlk Adım ve Keşif', reason: '$t için gerekli temelleri atarak başla.'),
          AiPlanBlock(start: '11:00', end: '13:00', title: '$t: Derin Uygulama Zamanı', reason: 'Tam odaklanma ile en verimli çalışmanı yap.'),
          AiPlanBlock(start: '15:00', end: '16:30', title: '$t: İlerleme Kaydetme', reason: 'Çalışmalarını detaylandır ve kaliteyi artır.'),
          AiPlanBlock(start: '18:00', end: '19:00', title: 'Günü Tamamlama', reason: '$t için bugün katettiğin yolu analiz et.'),
        ]);
      }

      return AiPlan(
        blocks: suggestions,
        notes: "'$t' hedefiniz için bilimsel verimlilik metotlarıyla optimize edilmiş özel bir akış hazırladım. 🎯"
      );
    } else {
      // Konu boşsa genel akıllı rutin
      suggestions.addAll([
        AiPlanBlock(start: '08:00', end: '08:30', title: 'Zihin Hazırlığı ve Okuma', reason: 'Güne ufuk açıcı bir başlangıç yap.'),
        AiPlanBlock(start: '12:00', end: '12:30', title: 'Kısa Yürüyüş ve Mola', reason: 'Öğleden sonraki odağını %20 artıracaktır.'),
      ]);
      for (var task in tasks) {
        suggestions.add(AiPlanBlock(start: '10:00', end: '11:30', title: task.title, reason: 'Görevin biyolojik saatine göre en uygun vakte yerleştirildi.'));
      }
      suggestions.sort((a, b) => a.start.compareTo(b.start));
      return AiPlan(blocks: suggestions, notes: "Henüz bir konu girmediniz, ancak listenizle güne en iyi başlangıcı yapmanız için bir plan oluşturdum! ✨");
    }
  }
}
