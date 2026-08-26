# coneccionone

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Asistente IA

El asistente del dashboard responde consultas de texto en todas las plataformas
y, en la versión web, también consultas por voz. Antes de enviar la consulta toma un resumen actual
de Firestore: cantidad de clientes, reparaciones, facturas, estados de las
reparaciones y ventas, gastos y ganancia del mes.

La aplicación usa la función `askGemini` del proyecto Firebase
`coneccionone-a9442`. La clave de Gemini queda guardada como secreto en Firebase
y no se incluye en Flutter.

```json
{
  "question": "¿Cómo fueron las ventas este mes?",
  "dashboard": { "resumen": { "ventas_mes": 0 } }
}
```

Y responder con:

```json
{ "answer": "Tu respuesta generada por IA" }
```

Antes de usar el asistente por primera vez, obtené una API key de Gemini en
[Google AI Studio](https://aistudio.google.com/app/apikey) y ejecutá desde la
raíz del proyecto:

```powershell
cd functions
npm install
cd ..
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions:askGemini
```

Luego podés ejecutar o compilar la aplicación normalmente; ya tiene configurada
la URL de producción:

```powershell
flutter run -d windows
```

No uses `AI_API_KEY` para la clave de Gemini: esa clave debe quedar únicamente
en Secret Manager. La función habilita CORS para la versión web.

El reconocimiento de voz usa las capacidades del navegador y requiere Chrome o
Edge, junto con el permiso de micrófono.
