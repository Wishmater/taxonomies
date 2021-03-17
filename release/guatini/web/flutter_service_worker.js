'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "assets/AssetManifest.json": "2da9481142d0b6b5f086c23965003045",
"assets/assets/audio/Accipiter_gundlachi_audio_20181024_123729_0.mp3": "90aab758e8f2a819cd4f687715954292",
"assets/assets/audio/Agelaius_assimilis_audio_20181031_225641_0.mp3": "e43d6acc2c2c83c5d01e166a0d58d1cf",
"assets/assets/audio/Buteogallus_gundlachii_audio_20181024_124806_0.mp3": "20170f1b79d40aaabe1967534ee8053b",
"assets/assets/audio/Chondrohierax_wilsonii_audio_20181024_122517_0.mp3": "e36cf3af41da2a6ee552f0a797e425d4",
"assets/assets/audio/Colaptes_fernandinae_audio_20181031_114522_0.mp3": "a308565552007d8b126ff4a28cb452b1",
"assets/assets/audio/Ferminia_cerverai_audio_20181031_205454_0.mp3": "053598de5ff3d0e6535811a33ad3eb60",
"assets/assets/audio/Geotrygon_caniceps_audio_20181022_153228_0.mp3": "22c23e8b03700297eaa1d56912da912f",
"assets/assets/audio/Glaucidium_siju_audio_20181024_120028_0.mp3": "08b2e83266bfef2e6acaf9f5bec5f66e",
"assets/assets/audio/Icterus_melanopsis_audio_20181031_224517_0.mp3": "2c26304966705e09285da93b4d647591",
"assets/assets/audio/Margarobyas_lawrencii_audio_20181024_121636_0.mp3": "4df00c43c8ec5ac825bf4678f08deea1",
"assets/assets/audio/Mellisuga_helenae_audio_20181022_154831_0.mp3": "9540987687d589ce465a4f9d2d0eb043",
"assets/assets/audio/Myadestes_elisabeth_audio_20181031_210428_0.mp3": "2d33baa913ea49a14247f7728763f60d",
"assets/assets/audio/Polioptila_lembeyei_audio_20181031_204340_0.mp3": "3bdc2c18f394d915c3508fff6f4dbcb5",
"assets/assets/audio/Priotelus_temnurus_audio_20181031_105408_0.mp3": "1ac239f7751f5ccdd9d11271b0984c4c",
"assets/assets/audio/Psittacara_euops_audio_20181031_121348_0.mp3": "c06c6c5b07257ce989b153cec612b085",
"assets/assets/audio/Ptiloxena_atroviolacea_audio_20181031_230504_0.mp3": "82e5e481e55a0ded04db132e7010be87",
"assets/assets/audio/Starnoenas_cyanocephala_audio_20181022_150807_0.mp3": "7e8208b37d0e1331b8261c78cb6a13b0",
"assets/assets/audio/Teretistris_fernandinae_audio_20181031_212427_0.mp3": "dff56de91a5139fa04ec58011cab22b4",
"assets/assets/audio/Teretistris_fornsi_audio_20181031_223651_0.mp3": "66e1c83a660e8c0495bb9db6e503a29f",
"assets/assets/audio/Todus_multicolor_audio_20181031_110622_0.mp3": "1da80e155e043cd10bfa92275b8d16ab",
"assets/assets/audio/Torreornis_inexpectata_audio_20181031_211305_0.mp3": "011812a6ac39a9114776ed9723d77df9",
"assets/assets/audio/Vireo_gundlachii_audio_20181031_202958_0.mp3": "6a619a56e4eff01f1b979022b0db737a",
"assets/assets/audio/Xiphidiopicus_percussus_audio_20181031_115703_0.mp3": "4b724575b9420241a27dd67a551f8807",
"assets/assets/config.properties": "a39bd41535eddff9ded053a546271984",
"assets/assets/image/Accipiter_gundlachi_image_20181024_123729_1.jpg": "feffcb56b6ad25dfd43613396f3b97fe",
"assets/assets/image/Agelaius_assimilis_image_20181031_225641_1.jpg": "0be90b7adba15ec6510fdeef71dd6dcc",
"assets/assets/image/Buteogallus_gundlachii_image_20181024_124806_1.jpg": "fedbe3f2c4155059327494c24d90c119",
"assets/assets/image/Chondrohierax_wilsonii_image_20181024_122517_1.jpg": "b49e44370fde623a6a03fa7f9b226f48",
"assets/assets/image/Coccyzus_merlini_image_20181024_094711_0.jpg": "d229144a3c32907e4a46e7b277d6aa50",
"assets/assets/image/Colaptes_fernandinae_image_20181031_114522_1.jpg": "e8d2f9f2100c2996db4d48be20ae97da",
"assets/assets/image/Cyanolimnas_cerverai_image_20181024_114844_0.jpg": "c727eee123d24b8c06dc7d4728351a52",
"assets/assets/image/Ferminia_cerverai_image_20181031_205454_1.jpg": "cb2302193f75042149b9c4fc2d135c28",
"assets/assets/image/Geotrygon_caniceps_image_20181022_153228_1.jpg": "183053500a38a214b4a083d7cd0ba3e9",
"assets/assets/image/Glaucidium_siju_image_20181024_120028_1.jpg": "31831efc67559ffa8320b33b9fb5197f",
"assets/assets/image/Icterus_melanopsis_image_20181031_224517_1.jpg": "b791e6e248f2741af47e98c1f5c6074b",
"assets/assets/image/Margarobyas_lawrencii_image_20181024_121636_1.jpg": "7fecd69b85a70b82230f14e0e0376373",
"assets/assets/image/Mellisuga_helenae_image_20181022_154831_1.jpg": "9d81e0ab156acc3df6759e65bbdecb8c",
"assets/assets/image/Myadestes_elisabeth_image_20181031_210428_1.jpg": "ffc8bd7d4a0c756832fdb7cfaef872e3",
"assets/assets/image/Polioptila_lembeyei_image_20181031_204340_1.jpg": "2fa094d96c2509603cd8eebcc2bbda9f",
"assets/assets/image/Priotelus_temnurus_image_20181031_105408_1.jpg": "51e04dffbc6cba5289f9ad7d3f67db95",
"assets/assets/image/Psittacara_euops_image_20181031_121348_1.jpg": "481a8e3e20a81ad28b07a5adc1e1ead4",
"assets/assets/image/Ptiloxena_atroviolacea_image_20181031_230504_1.jpg": "f6cd6d66630c628f601022b9b9274809",
"assets/assets/image/Starnoenas_cyanocephala_image_20181022_150807_1.jpg": "ab06d2569e58c797a9e07bcb6a28d9b7",
"assets/assets/image/Teretistris_fernandinae_image_20181031_212427_1.jpg": "242758bbf69f0a5ffbffd7a537af71d0",
"assets/assets/image/Teretistris_fornsi_image_20181031_223651_1.jpg": "9b671662e1f3d42b147bd691eca7fb45",
"assets/assets/image/Todus_multicolor_image_20181031_110622_1.jpg": "d7aae50ff464ded9c73b5b5145b914f0",
"assets/assets/image/Torreornis_inexpectata_image_20181031_211305_1.jpg": "62342cfaebb4146e3e4c77d75a7b55aa",
"assets/assets/image/Vireo_gundlachii_image_20181031_202958_1.jpg": "ae5c38fd9c1e93e92145ca97979af009",
"assets/assets/image/Xiphidiopicus_percussus_image_20181031_115703_1.jpg": "d4e296ae97ff171fe5d9417ca02aa5cb",
"assets/assets/logo.png": "0af8228dee44eb6cbfcb5a2f90d0422a",
"assets/assets/main.db": "5de49c4adb97262523297287cc2a8b24",
"assets/FontManifest.json": "2542628db249ae0a83a9cffd973dd604",
"assets/fonts/MaterialIcons-Regular.otf": "a68d2a28c526b3b070aefca4bac93d25",
"assets/NOTICES": "a9ca10cc13232aff4f1267dfe1e4de49",
"assets/packages/flutter_icons/fonts/AntDesign.ttf": "3a2ba31570920eeb9b1d217cabe58315",
"assets/packages/flutter_icons/fonts/Entypo.ttf": "744ce60078c17d86006dd0edabcd59a7",
"assets/packages/flutter_icons/fonts/EvilIcons.ttf": "140c53a7643ea949007aa9a282153849",
"assets/packages/flutter_icons/fonts/Feather.ttf": "6beba7e6834963f7f171d3bdd075c915",
"assets/packages/flutter_icons/fonts/FontAwesome.ttf": "b06871f281fee6b241d60582ae9369b9",
"assets/packages/flutter_icons/fonts/FontAwesome5_Brands.ttf": "c39278f7abfc798a241551194f55e29f",
"assets/packages/flutter_icons/fonts/FontAwesome5_Regular.ttf": "f6c6f6c8cb7784254ad00056f6fbd74e",
"assets/packages/flutter_icons/fonts/FontAwesome5_Solid.ttf": "b70cea0339374107969eb53e5b1f603f",
"assets/packages/flutter_icons/fonts/Foundation.ttf": "e20945d7c929279ef7a6f1db184a4470",
"assets/packages/flutter_icons/fonts/Ionicons.ttf": "b2e0fc821c6886fb3940f85a3320003e",
"assets/packages/flutter_icons/fonts/MaterialCommunityIcons.ttf": "3c851d60ad5ef3f2fe43ebd263490d78",
"assets/packages/flutter_icons/fonts/MaterialIcons.ttf": "a37b0c01c0baf1888ca812cc0508f6e2",
"assets/packages/flutter_icons/fonts/Octicons.ttf": "73b8cff012825060b308d2162f31dbb2",
"assets/packages/flutter_icons/fonts/SimpleLineIcons.ttf": "d2285965fe34b05465047401b8595dd0",
"assets/packages/flutter_icons/fonts/weathericons.ttf": "4618f0de2a818e7ad3fe880e0b74d04a",
"assets/packages/flutter_icons/fonts/Zocial.ttf": "5cdf883b18a5651a29a4d1ef276d2457",
"assets/packages/from_zero_ui/assets/i18n/en.json": "835ee67e7372c990698ae0b1e1697b82",
"assets/packages/from_zero_ui/assets/i18n/es.json": "5c940ef98ec3461970323b3e3af51a09",
"assets/packages/open_iconic_flutter/assets/open-iconic.woff": "3cf97837524dd7445e9d1462e3c4afe2",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"index.html": "b4441e29c2fd3af3f7c5f9b1d8513b9d",
"/": "b4441e29c2fd3af3f7c5f9b1d8513b9d",
"main.dart.js": "994d0eb6461b3aa2c3fbda91c7e25550",
"manifest.json": "a4aff9a6581f19f3cf78587b8f9b2add",
"sql-wasm.js": "63ac58d843bccce6c3c4b0c1cd6c4422",
"sql-wasm.wasm": "867016e4a77ae35dc11f37e333b95caa"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "/",
"main.dart.js",
"index.html",
"assets/NOTICES",
"assets/AssetManifest.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      // Provide a 'reload' param to ensure the latest version is downloaded.
      return cache.addAll(CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');

      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }

      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#')) {
    key = '/';
  }
  // If the URL is not the RESOURCE list, skip the cache.
  if (!RESOURCES[key]) {
    return event.respondWith(fetch(event.request));
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache. Ensure the resources are not cached
        // by the browser for longer than the service worker expects.
        var modifiedRequest = new Request(event.request, {'cache': 'reload'});
        return response || fetch(modifiedRequest).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    return self.skipWaiting();
  }

  if (event.message === 'downloadOffline') {
    downloadOffline();
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey in Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
