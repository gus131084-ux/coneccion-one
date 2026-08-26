const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret, defineString} = require('firebase-functions/params');
const logger = require('firebase-functions/logger');

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const geminiModel = defineString('GEMINI_MODEL', {default: 'gemini-3.7-flash'});

function responseText(response) {
  const parts = response?.candidates?.[0]?.content?.parts;
  return Array.isArray(parts) ? parts.map((part) => part?.text ?? '').join('').trim() : '';
}

exports.askGemini = onRequest(
  {region: 'southamerica-east1', cors: true, secrets: [geminiApiKey], timeoutSeconds: 60},
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).json({error: 'Usá el método POST.'});
      return;
    }
    const question = request.body?.question;
    const dashboard = request.body?.dashboard;
    if (typeof question !== 'string' || question.trim().length === 0) {
      response.status(400).json({error: 'Falta una pregunta válida.'});
      return;
    }
    if (question.length > 2000 || dashboard == null || typeof dashboard !== 'object') {
      response.status(400).json({error: 'La consulta es demasiado grande o el resumen es inválido.'});
      return;
    }
    const prompt = [
      'Sos el asistente de un servicio técnico de celulares en Argentina.',
      'Respondé siempre en español claro, de forma breve y útil.',
      'Usá exclusivamente el resumen provisto; si no alcanza para responder, indicá qué dato falta.',
      `Resumen del negocio: ${JSON.stringify(dashboard)}`,
      `Pregunta: ${question.trim()}`,
    ].join('\n\n');
    try {
      const geminiResponse = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel.value()}:generateContent`,
        {
          method: 'POST',
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': geminiApiKey.value()},
          body: JSON.stringify({
            contents: [{role: 'user', parts: [{text: prompt}]}],
            generationConfig: {temperature: 0.3, maxOutputTokens: 500},
          }),
        },
      );
      const payload = await geminiResponse.json();
      if (!geminiResponse.ok) {
        logger.error('Gemini rechazó la consulta', {status: geminiResponse.status, payload});
        response.status(502).json({error: 'Gemini no pudo procesar la consulta.'});
        return;
      }
      const answer = responseText(payload);
      if (!answer) {
        response.status(502).json({error: 'Gemini no devolvió una respuesta utilizable.'});
        return;
      }
      response.json({answer});
    } catch (error) {
      logger.error('Error al consultar Gemini', error);
      response.status(500).json({error: 'No se pudo conectar con Gemini.'});
    }
  },
);
