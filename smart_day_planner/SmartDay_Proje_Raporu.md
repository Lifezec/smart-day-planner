# SmartDay: Yapay Zeka Destekli Akıllı Gün Planlayıcı - Proje Raporu

## 1. Giriş
Günümüzde artan bilgi yoğunluğu ve karmaşık günlük rutinler, bireylerin zaman yönetimi konusunda ciddi zorluklar yaşamasına neden olmaktadır. SmartDay, bu karmaşayı sadeleştirmek ve kullanıcılara verimli bir çalışma disiplini kazandırmak amacıyla geliştirilmiş bir mobil asistandır.

## 2. Problem Tanımı
Geleneksel yapılacaklar listesi uygulamaları genellikle statik bir yapıya sahiptir. Kullanıcılar görevlerini eklerler ancak hangi görevin ne zaman yapılacağı, önceliklendirme ve karar verme süreçlerinde (karar yorgunluğu) tek başlarına kalırlar. Ayrıca, kritik görevlerin unutulması ve gelişim takibinin yapılamaması verimliliği düşüren temel unsurlardır.

## 3. Çözüm: SmartDay
SmartDay, klasik bir ajanda uygulamasının ötesine geçerek;
- **Yapay Zeka (AI)** desteğiyle gününüzü planlar.
- **Kesin Zamanlı Bildirimler** ile unutkanlığı önler.
- **İstatistiksel Analizler** ile gelişiminizi görselleştirir.

## 4. Teknik Mimari ve Kullanılan Teknolojiler
Uygulama, modern yazılım mimarisi standartlarına uygun olarak geliştirilmiştir:
- **Framework:** Flutter (Google tarafından geliştirilen cross-platform SDK).
- **State Management:** Flutter Riverpod (Reaktif ve güvenli durum yönetimi).
- **Yerel Veritabanı:** Sqflite (Kullanıcı verilerinin cihazda güvenli ve hızlı saklanması).
- **Zaman Yönetimi:** Timezone kütüphanesi ile yerel saat dilimine tam uyum.
- **Bildirimler:** Flutter Local Notifications (Exact Alarm desteği ile).

## 5. Temel Fonksiyonlar
### 5.1. AI Gün Planlayıcı
AI Servisi, kullanıcının o günkü görevlerini analiz eder. Görevlerin önceliğine (Yüksek, Orta, Düşük) ve kategorisine göre en mantıklı akışı oluşturur. Kullanıcı, AI önerilerini tek bir butonla kendi ajandasına dahil edebilir.

### 5.2. Akıllı Bildirim Sistemi
Android 12 ve üzeri sürümlerdeki kesin alarm (Exact Alarm) gereksinimlerini karşılayan sistem, kullanıcıyı tam vaktinde uyarır.

### 5.3. Esnek Kullanıcı Arayüzü
Kullanıcı deneyimi odaklı tasarım, açık ve koyu mod desteği sunar. Takvim entegrasyonu sayesinde geçmiş ve gelecek günlerin planları kolayca yönetilebilir.

## 6. Sonuç
SmartDay, teknolojiyi gündelik hayatın bir parçası haline getirerek bireysel verimliliği maksimize etmeyi başarmıştır. Yapay zeka entegrasyonu ve kullanıcı dostu arayüzü ile modern zaman yönetimi ihtiyaçlarına eksiksiz bir çözüm sunmaktadır.
