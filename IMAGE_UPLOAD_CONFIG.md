# Chat SDK - Rasm Yuklash Uchun Alohida URL

## 🔥 Yangi Xususiyat: Rasm Yuklash Uchun Alohida Base URL

Endi Chat SDK rasm yuklash uchun alohida URL qo'llab-quvvatlaydi. Bu ko'p hollarda rasm serverlari asosiy API serveridan alohida bo'lganda foydalidir.

## 📋 Konfiguratsiya

```dart
final config = ChatConfig(
  baseUrl: 'https://api.example.com/v1',           // Asosiy API
  imageUploadBaseUrl: 'https://files.example.com', // Rasm yuklash serveri
  webSocketUrl: 'wss://ws.example.com/chat/',
  getConversationEndpoint: 'chat.conversation',
  getHistoryEndpoint: 'chat.history',
  uploadImageEndpoint: '/upload',                  // imageUploadBaseUrl ga nisbatan
  authTokenProvider: () async => 'your-token',
);
```

## 🎯 Ishlash Prinsipi

1. **Agar `imageUploadBaseUrl` berilgan bo'lsa:**
   ```
   Rasm yuklash: https://files.example.com/upload
   ```

2. **Agar `imageUploadBaseUrl` berilmagan bo'lsa:**
   ```
   Rasm yuklash: https://api.example.com/v1/upload
   ```

## ⚡ Afzalliklari

- ✅ **Alohida rasm serverlari** bilan ishlash
- ✅ **Uzoqroq timeout** - rasm yuklash 60 soniya
- ✅ **Yaxshi error handling** va logging
- ✅ **Backward compatibility** - eski kodlar o'zgarishsiz ishlaydi

## 🔧 Ishlatish Misoli

```dart
// Oddiy ishlatish - faqat baseUrl
ChatConfig(
  baseUrl: 'https://api.example.com',
  // imageUploadBaseUrl berilmagan, shu sababli baseUrl ishlatiladi
)

// Alohiida rasm serveri bilan ishlatish
ChatConfig(
  baseUrl: 'https://api.example.com',
  imageUploadBaseUrl: 'https://cdn.example.com',
)

// CDN yoki cloud storage bilan ishlatish
ChatConfig(
  baseUrl: 'https://api.example.com',
  imageUploadBaseUrl: 'https://s3.amazonaws.com/my-bucket',
)
```

## 📊 Texnik Tafsilotlar

- **Asosiy API** - 30 soniya timeout
- **Rasm yuklash** - 60 soniya timeout
- **Alohida Dio instance** - har biri uchun optimal konfiguratsiya
- **Avto-fallback** - agar alohida URL ishlamasa, asosiy URL ga o'tadi

Bu xususiyat Chat SDK'ni yanada flexible va enterprise-ready qiladi! 🚀
