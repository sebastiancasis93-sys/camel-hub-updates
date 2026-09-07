CAMEL HUB UPDATER 1.0.0
========================

Este paquete fue generado desde TU Bots.zip actual.

Personajes detectados:
 - Athalar
 - Gampi
 - Lemac
 - Tronchito
 - Valyria1

CORE COMUN
-----------
Archivos comunes actualizables: 103
Archivos comunes actuales obtenidos de los bots: 102
Updater: 1 archivo adicional

COMO PUBLICARLO
---------------
1. Sube el CONTENIDO de esta carpeta a un hosting HTTPS estatico.
2. Ejecuta:
     python build_release.py https://TU-HOST
3. Sube tambien el manifest.json generado.
4. En cada bot abre CAMEL UPDATER y pega:
     https://TU-HOST/manifest.json
5. Pulsa Check.

IMPORTANTE
----------
No hace falta pagar por un servidor para esta estructura.
El bot solo necesita poder descargar archivos HTTPS estaticos.

NO ACTUALIZA
------------
- storage
- AttackBot/HealBot profiles
- CaveBot configs
- TargetBot configs
- _Loader.lua
- AthalarIcons.lua
- CamelQuickActions.lua
- ingame_editor.lua
- AthalarMacroRegistry.lua

PARA UNA VERSION 1.0.1
----------------------
1. Modifica el archivo comun dentro de release/.
2. Cambia VERSION en build_release.py.
3. Ejecuta nuevamente build_release.py con tu misma URL HTTPS.
4. Publica release/ + manifest.json.
5. Los personajes veran los hashes distintos y solo bajaran lo cambiado.
