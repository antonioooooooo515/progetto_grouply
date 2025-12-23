/* web/firebase-messaging-sw.js */

// IMPORT compat
importScripts("https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js");

self.addEventListener("install", function () {
    console.log("[SW] install");
    self.skipWaiting();
});

self.addEventListener("activate", function (event) {
    console.log("[SW] activate");
    event.waitUntil(self.clients.claim());
});

var firebaseConfig = {
    apiKey: "AIzaSyABtE542Tjl37l-q4u65hWELHFFDAN14m8",
    authDomain: "grouply-team-manager.firebaseapp.com",
    projectId: "grouply-team-manager",
    storageBucket: "grouply-team-manager.firebasestorage.app",
    messagingSenderId: "145866469912",
    appId: "1:145866469912:web:ce856118279277100ec96d",
    measurementId: "G-J3SQB9VH8X"
};

try {
    firebase.initializeApp(firebaseConfig);
    console.log("[SW] firebase initialized");

    var messaging = firebase.messaging();

    messaging.onBackgroundMessage(function (payload) {
        console.log("[SW] onBackgroundMessage", payload);

        var title = "Grouply";
        var body = "";

        if (payload && payload.notification) {
            if (payload.notification.title) title = payload.notification.title;
            if (payload.notification.body) body = payload.notification.body;
        }

        var options = {
            body: body,
            // se non hai le icone PWA, metti "/favicon.png"
            icon: "/icons/Icon-192.png"
        };

        self.registration.showNotification(title, options);
    });
} catch (e) {
    console.error("[SW] init error", e);
    throw e;
}
