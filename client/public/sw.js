self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
self.addEventListener('push', (event) => {
  const data = event.data?.json?.() ?? { title: 'تذكير ممثلي', body: 'لديك تذكير جديد' };
  event.waitUntil(self.registration.showNotification(data.title ?? 'تذكير ممثلي', {
    body: data.body ?? 'حان موعد التذكير',
    icon: '/momathili-mark.svg',
    badge: '/momathili-mark.svg',
    tag: data.tag ?? 'momathili-reminder',
    data: data.url ?? '/',
    renotify: true,
  }));
});
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow(event.notification.data || '/'));
});
