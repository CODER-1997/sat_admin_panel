/// Cloudflare Worker manzili.
/// `wrangler deploy` dan keyin chiqqan URL ni shu yerga yozing yoki ishga
/// tushirishda bering:
///   flutter run --dart-define=STORAGE_URL=https://sat-storage.xxx.workers.dev
const String kStorageUrl = String.fromEnvironment(
  'STORAGE_URL',
  defaultValue: 'https://sat-storage.YOUR_SUBDOMAIN.workers.dev',
);
