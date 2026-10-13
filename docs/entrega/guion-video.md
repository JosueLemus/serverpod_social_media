# Guion del video: Nexo Social

Hackathon "Build Something Real" de Serverpod. El video tiene que durar
**menos de 2 minutos**. Apuntamos a **1:50** para tener margen al exportar.

Todo se graba **contra producción** y con **dos dispositivos**. No se
muestra nada local ni nada que siga en mock.

| | |
|---|---|
| Duración | 1:50. Al exportar, nunca más de 1:55 |
| Web | https://52-45-123-215.sslip.io/ |
| API | https://api.52-45-123-215.sslip.io/ |
| **Dispositivo A** | Teléfono Android con el APK de release, que apunta a producción. **Elena Vega** (`elena@nexo.demo`): la creadora y host |
| **Dispositivo B** | Chrome en una ventana de **1100 px de ancho o más**, para que el rail muestre "Moderación", o una tablet. **Lucía Moderadora** (`moderador@nexo.demo`): mira el vivo y modera |
| Fuera de cámara | **Troll 99** (`troll@nexo.demo`), en una ventana de incógnito o en un tercer teléfono: escribe el comentario ofensivo. **Tomás Ríos** (`tomas@nexo.demo`) aparece sólo en la preparación: reporta la publicación |
| Contraseña | `nexo-demo-2026`, la misma en todas las cuentas |
| Montaje | Pantalla dividida, con A a la izquierda y B a la derecha, para que se vea que las cosas pasan en los dos a la vez. La voz en off se graba aparte |

**Por qué B es Lucía y no Tomás:** ocultar un comentario exige el scope
`moderator`, y con la cuenta de Tomás el servidor responde `forbidden`. Que el
permiso lo decida el servidor es justamente lo que el video quiere contar.

### Qué no tocar durante la toma

Estas cosas están en pantalla pero **no llegan al servidor**. Mostrarlas
contaría algo que no es cierto:

- En la hoja de moderación del chat, sólo **"Ocultar comentario"**. Todavía
  no llegan al servidor "Silenciar usuario", "Bloquear usuario del canal" ni
  "Reportar a moderación central".
- En la cola de reportes, sólo **"Ocultar"** o **"Descartar"**. Nada de
  "Sancionar al autor".
- **No tocar "Publicar replay".** Publicarlo a mano cancela la Future Call,
  que es justo lo que muestra la escena 7.
- No abrir la Consola de operador, membresías ni pagos: siguen en mock.
- En el Studio, no quedarse en "Nuevos subs (mock)", "Donaciones (mock)",
  "Regalos" ni "Filtro EQ".

---

## Escenas

### 1. Qué es Nexo

| | |
|---|---|
| Tiempo | **0:00–0:12** (12 s) |
| A · Elena (teléfono) | El Inicio de Elena. En la barra de estado se ve **4G/5G y el Wi-Fi apagado** |
| B · Lucía (web) | Chrome con la barra de dirección en `52-45-123-215.sslip.io`, en el Inicio de Lucía |
| Voz en off | "Esto es Nexo, una red social para creadores y sus comunidades. Flutter en el cliente, Serverpod en el servidor, en producción en AWS." |
| Serverpod en pantalla | Rótulo: **Flutter + Serverpod 4 · producción en AWS** |

### 2. Una publicación con foto

| | |
|---|---|
| Tiempo | **0:12–0:26** (14 s) |
| A · Elena (teléfono) | Toca **+**, elige una foto de la galería, escribe "Bocetos para la masterclass de hoy" y publica. Unos segundos después, el badge de **Actividad** sube: "Lucía Moderadora · Le gustó tu publicación" |
| B · Lucía (web) | Recarga Inicio (en la tablet, desliza hacia abajo). La foto aparece en **"De quienes sigues"**. La abre y toca el corazón |
| Voz en off | "Elena publica una foto: la app la sube directo al storage y el servidor la verifica antes de crear el post. Lucía le da like, y el aviso llega al instante." |
| Serverpod en pantalla | Rótulos: **Cloud Storage · subida directa** y **Streaming Method · notifications.watch**. Detrás: `session.storage.createUploadDescription` y `verifyUpload`, `Post` y `Like` con el ORM y el aviso por `session.messages` |

### 3. Elena sale al aire

| | |
|---|---|
| Tiempo | **0:26–0:41** (15 s) |
| A · Elena (teléfono) | **Perfil → menú → Creator Studio → "Salir al aire"** sobre el show programado (o **"Transmitir ahora"** con un título; ver la preparación). Aparece la cámara con la insignia **"En vivo"**. **Espectadores** pasa de 0 a 1 cuando entra Lucía |
| B · Lucía (web) | Sin tocar nada, el vivo aparece en **"En vivo ahora"** y el badge de Actividad sube: "Elena Vega · Está en vivo: …". Lucía toca **"Unirme al Live"** y ve la cámara de Elena |
| Voz en off | "Elena sale al aire y sus seguidores se enteran sin recargar. El video va por Agora, pero el token lo firma el servidor: sólo el host transmite, el resto mira." |
| Serverpod en pantalla | Rótulos: **live.start · transacción con bloqueo y auditoría**, **live.mediaToken · el servidor decide quién publica** y **Streaming Methods · live.watchIndex y live.watch** |

### 4. Moderar dentro del vivo

| | |
|---|---|
| Tiempo | **0:41–1:00** (19 s) |
| Fuera de cámara | Troll 99 escribe en el chat: "Esto es una estafa, no le crean nada" |
| A · Elena (teléfono) | El comentario aparece sobre el video y, segundos después, **desaparece solo** |
| B · Lucía (web) | El comentario aparece. Lucía lo **mantiene apretado** (en web, clic sostenido) → **"Ocultar comentario"** → aviso de confirmación |
| Voz en off | "Entra un comentario ofensivo. Lucía es moderadora: lo mantiene apretado, lo oculta, y desaparece de todas las pantallas a la vez. El servidor revisa su scope, lo registra en la auditoría en la misma transacción y lo avisa por el stream del vivo." |
| Serverpod en pantalla | Rótulos: **scope moderator**, **live.hideChat · transacción + AuditLog** y **session.messages → live.watch** |

### 5. La cola de reportes

| | |
|---|---|
| Tiempo | **1:00–1:12** (12 s) |
| A · Elena (teléfono) | Fuera de cuadro: **B a pantalla completa** |
| B · Lucía (web) | Sale de la sala → **Moderación** (en el rail) → **"Cola de reportes"**. Ahí está la publicación de Troll 99 que reportó Tomás. Lucía toca **"Ocultar"** y la tarjeta sale de la cola |
| Voz en off | "Lo que se reporta fuera del vivo llega a una cola. Tomás reportó esta publicación: Lucía la oculta y todos sus reportes se cierran en un solo paso." |
| Serverpod en pantalla | Rótulo: **moderation.resolve · ocultar, cerrar reportes y auditar en una sola transacción** |

### 6. Fin del vivo y un mensaje directo

| | |
|---|---|
| Tiempo | **1:12–1:22** (10 s) |
| A · Elena (teléfono) | Studio → **"Finalizar vivo"**: la insignia pasa a **"Grabado"**. Después sube el badge de **Mensajes**: Elena abre el chat y contesta "¡Gracias por estar!" |
| B · Lucía (web) | Va al perfil de Elena → **"Enviar mensaje"** → "¡Gracias por el vivo!". La respuesta de Elena le llega sin recargar |
| Voz en off | "Elena termina el vivo. Lucía le escribe por mensaje directo, y la respuesta llega igual de rápido: es otro stream, uno por cuenta." |
| Serverpod en pantalla | Rótulos: **Streaming Method · messages.watch** y **messages.open · una sola conversación por par, con advisory lock** |

### 7. El replay se publica solo

| | |
|---|---|
| Tiempo | **1:22–1:36** (14 s) |
| A · Elena (teléfono) | Rótulo **"1 minuto después"**. En el Studio, la insignia pasa de **"Grabado"** a **"Replay"** sin que nadie toque nada |
| B · Lucía (web) | El replay aparece en el perfil de Elena (o en "Replays", en Inicio). Va un **inserto de 2 s grabado en la preparación**: la notificación `"Masterclass de Diseño Mobile" empieza en 15 minutos` |
| Voz en off | "Un minuto después, el replay se publica solo. Es una Future Call de Serverpod, igual que el aviso quince minutos antes del show y la cancelación del show que nunca arrancó." |
| Serverpod en pantalla | 2 s de `services/serverpod/nexo_server/lib/src/modules/live/future_calls/live_show_future_call.dart`, con `remind`, `expire` y `publishReplay` a la vista. Rótulo: **Future Calls · guardadas en la base, sobreviven a un reinicio** |

### 8. El código, el CI y lo que sigue

| | |
|---|---|
| Tiempo | **1:36–1:50** (14 s) |
| A y B | Pantalla completa del navegador. **0–2 s:** el README en GitHub, con la tabla "Probarlo ya". **2–5 s:** Actions → Deploy → la última corrida en verde. **5–14 s:** placa final con el logo, la web y el repo |
| Voz en off | "Cada push a main corre los tests, también los de integración con withServerpod, y se despliega solo en AWS. Lo que sigue: la consola de sanciones en el servidor, pagos y push." |
| Serverpod en pantalla | Rótulo: **serverpod_test · withServerpod**. En la placa final: `52-45-123-215.sslip.io` · `github.com/JosueLemus/serverpod_social_media` |

---

## Voz en off, de corrido

Para leerla de una sola vez. Son unas 240 palabras: a un ritmo tranquilo
(2,4 palabras por segundo) da 1:40, y quedan 10 segundos para que las
imágenes respiren. Si la toma pasa de 1:50, lo primero que se recorta es el
final de la escena 6 ("es otro stream, uno por cuenta").

> Esto es Nexo, una red social para creadores y sus comunidades. Flutter en
> el cliente, Serverpod en el servidor, en producción en AWS.
>
> Elena publica una foto: la app la sube directo al storage y el servidor la
> verifica antes de crear el post. Lucía le da like, y el aviso llega al
> instante.
>
> Elena sale al aire y sus seguidores se enteran sin recargar. El video va
> por Agora, pero el token lo firma el servidor: sólo el host transmite, el
> resto mira.
>
> Entra un comentario ofensivo. Lucía es moderadora: lo mantiene apretado,
> lo oculta, y desaparece de todas las pantallas a la vez. El servidor
> revisa su scope, lo registra en la auditoría en la misma transacción y lo
> avisa por el stream del vivo.
>
> Lo que se reporta fuera del vivo llega a una cola. Tomás reportó esta
> publicación: Lucía la oculta y todos sus reportes se cierran en un solo
> paso.
>
> Elena termina el vivo. Lucía le escribe por mensaje directo, y la
> respuesta llega igual de rápido: es otro stream, uno por cuenta.
>
> Un minuto después, el replay se publica solo. Es una Future Call de
> Serverpod, igual que el aviso quince minutos antes del show y la
> cancelación del show que nunca arrancó.
>
> Cada push a main corre los tests, también los de integración con
> withServerpod, y se despliega solo en AWS. Lo que sigue: la consola de
> sanciones en el servidor, pagos y push.

---

## Checklist de preparación

### El servidor

- [ ] La última corrida de **Actions → Deploy** está en verde (la del merge
      #21, el perfil completo, terminó bien).
- [ ] **No mergear nada a `main` mientras se graba.** Cada push redespliega y
      reinicia el servidor, y un reinicio corta el vivo a la mitad.

### Las cuentas y los datos

- [ ] **A:** Elena logueada en un APK de release compilado desde el último
      `main`. La web se actualiza sola con cada deploy, pero el APK no: uno
      viejo no tiene la pestaña Mensajes ni el perfil completo, y el que
      apuntaba a la Mac no sirve.
- [ ] **B:** Lucía (`moderador@nexo.demo`) logueada en Chrome.
- [ ] **Fuera de cámara:** Troll 99 (`troll@nexo.demo`) logueado en una
      ventana de incógnito o en otro teléfono, ya adentro de la sala cuando
      Elena sale al aire.
- [ ] **Lucía sigue a Elena.** No viene así en el seed, y sin eso no le llega
      ni "Está en vivo" ni el aviso de los 15 minutos. Tomás y Troll 99 ya la
      siguen.
- [ ] **La publicación reportada:** Troll 99 publica un texto que se lea
      como abuso, pero sin insultos reales (por ejemplo, "Esta creadora vende
      humo, no compren nada"), y Tomás lo reporta desde el feed (menú de la
      publicación → **Reportar**).
- [ ] **La cola limpia:** con Lucía, descartar los reportes viejos para que en
      la toma quede sólo el de Troll 99.
- [ ] **Ningún vivo de Elena al aire.** Si quedó uno abierto de un ensayo,
      "Finalizar vivo". El servidor no deja abrir un segundo vivo.
- [ ] Una foto lista en la galería del teléfono para la escena 2.
- [ ] Permisos de cámara y micrófono ya concedidos en el teléfono, para que no
      aparezca el diálogo del sistema en la toma.

### El vivo: programado o "Transmitir ahora"

- **Programado (recomendado, porque deja grabar el aviso de 15 minutos):**
  1. Con Elena: Studio → **"Programar show"**, título "Masterclass de Diseño
     Mobile", que empiece **16 minutos después**.
  2. Un minuto más tarde le llega a Lucía `"Masterclass de Diseño Mobile"
     empieza en 15 minutos`. **Grabar ese momento en B**: es el inserto de la
     escena 7.
  3. Hacer la toma principal **antes de que pasen 30 minutos desde la hora de
     inicio**. Pasado ese tiempo, la Future Call `expire` cancela el show.
     En la escena 3, Elena toca **"Salir al aire"**.
- **"Transmitir ahora":** no hace falta programar nada. Elena escribe el
  título y sale. La escena 7 queda sin el inserto: la voz en off nombra el
  aviso igual, y el código en pantalla lo respalda.

### Los dispositivos

- [ ] **Teléfono:** Wi-Fi apagado y **datos móviles prendidos**, para que en
      la barra de estado se vea 4G/5G y quede claro que es producción. Brillo
      alto, batería por encima del 50 % y ahorro de batería apagado.
- [ ] **Notificaciones silenciadas:** "No molestar" en el teléfono y
      "Concentración" en la Mac. Las notificaciones de Nexo se ven igual,
      porque son de la app y no push.
- [ ] **Chrome:** sin extensiones a la vista, una sola pestaña, la barra de
      dirección visible (se tiene que leer `sslip.io`), zoom entre 100 y 125 %
      y la ventana de 1100 px de ancho o más.
- [ ] **El video en B:** comprobar en un ensayo que la cámara de Elena se ve
      en la web. Agora en web todavía es beta (R7 del SDD 0009): si no se ve,
      B pasa a ser una tablet Android con el mismo APK.
- [ ] **Un ensayo completo con cronómetro** antes de la toma buena.

---

## Cómo grabar la pantalla

### Android (dispositivo A, o B si es una tablet)

- **Desde el teléfono (Android 11 o superior):** en Ajustes rápidos, tocar
  **"Grabación de pantalla"**, elegir **sin audio** (la voz va aparte) y
  prender **"Mostrar toques en la pantalla"**. El archivo queda en la
  galería, en la carpeta Movies.
- **Desde la Mac, con cable:** `scrcpy --record=telefono.mp4` graba lo mismo
  que se ve en el espejo. Otra opción es `adb shell screenrecord
  /sdcard/a.mp4`, que corta a los 3 minutos y no graba audio.
- Si la tablet es un iPad: Centro de control → **Grabación de pantalla**.

### Web (dispositivo B)

- **macOS:** `Cmd + Shift + 5` → **"Grabar porción seleccionada"**, marcando
  la ventana de Chrome. También sirve OBS, con captura de ventana a 1080p y
  30 fps.
- **Windows:** `Win + Alt + R` (Xbox Game Bar) u OBS.

### Montaje

- **Para sincronizar los dos videos**, arrancar las dos grabaciones y hacer
  una marca que se vea en las dos pantallas: Elena manda un comentario y
  aparece en B. Ese cuadro alinea las dos pistas.
- Pantalla dividida A | B. Los rótulos de Serverpod van como texto
  sobreimpreso, abajo y en una línea.
- El jurado de Serverpod es internacional: conviene **quemar subtítulos en
  inglés**.
- Los tiempos muertos (el minuto que espera el replay, la carga de una foto)
  se cortan, siempre con un rótulo que diga cuánto pasó.
- Exportar en 1080p y comprobar que dure menos de 1:55. Subirlo a YouTube
  como **público** y pegar el link en el README ("Video de la demo") y en
  BuilderBase.

### Si algo falla en la toma

- **Una notificación no llega o el comentario no desaparece:** no se simula
  ni se edita para que parezca que anduvo. Se repite la toma.
- **El replay no cambia solo en el Studio:** salir y volver a entrar, o
  mostrarlo en el perfil de Elena. Lo publica el servidor, no la pantalla.
- **El video de Agora no conecta:** revisar en un ensayo la red del teléfono.
  Si persiste, B pasa a la tablet.

---

## Qué mostrar 5 segundos del repo y del CI (escena 8)

| Segundos | Qué | Dónde |
|---|---|---|
| 0–2 | El README, con la tabla **"Probarlo ya, sin instalar nada"** (la web, la API y el video) | https://github.com/JosueLemus/serverpod_social_media |
| 2–5 | **Actions → Deploy → la última corrida en verde**, con el grafo a la vista: `backend / check → server-image` y `app / check → web`, que terminan en `deploy` | https://github.com/JosueLemus/serverpod_social_media/actions/workflows/deploy.yml |

Si en el montaje sobran 2 segundos, el mejor agregado es el resumen de esa
misma corrida, donde están los links de Web y API. Muestra que el deploy
termina en la URL que el jurado va a abrir.
