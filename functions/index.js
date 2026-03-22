const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');
const { GoogleGenerativeAI } = require('@google/generative-ai');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

function getGeminiClient() {
  const key =
    process.env.GEMINI_API_KEY ||
    functions.config()?.gemini?.key ||
    '';

  if (!key) {
    throw new Error(
      'Missing Gemini API key. Set GEMINI_API_KEY env var or functions config gemini.key',
    );
  }

  return new GoogleGenerativeAI(key).getGenerativeModel({
    model: 'gemini-2.0-flash',
  });
}

async function retry(fn, attempts = 3, delayMs = 600) {
  let lastError = null;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (i < attempts - 1) {
        await new Promise((resolve) => setTimeout(resolve, delayMs * (i + 1)));
      }
    }
  }
  throw lastError;
}

function extractJsonObject(text) {
  const raw = (text || '').trim();
  if (!raw) return {};

  const fenceMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fenceMatch ? fenceMatch[1].trim() : raw;

  const firstBrace = candidate.indexOf('{');
  const lastBrace = candidate.lastIndexOf('}');
  const jsonText =
    firstBrace >= 0 && lastBrace > firstBrace
      ? candidate.slice(firstBrace, lastBrace + 1)
      : candidate;

  return JSON.parse(jsonText);
}

function normalizeLangMap(value, fallbackText = '') {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    const en = String(value.en || fallbackText || '').trim();
    const ta = String(value.ta || en).trim();
    const hi = String(value.hi || en).trim();
    return { en, ta, hi };
  }

  const base = String(value || fallbackText || '').trim();
  return { en: base, ta: base, hi: base };
}

async function translateSingleText(inputText) {
  const text = String(inputText || '').trim();
  if (!text) {
    return { ta: '', hi: '' };
  }

  const model = getGeminiClient();
  const prompt = [
    'Translate the following text into Tamil and Hindi.',
    'Keep meaning accurate and simple for farmers.',
    'Return ONLY valid JSON in this format:',
    '{"ta":"...","hi":"..."}',
    '',
    `Text: ${text}`,
  ].join('\n');

  const output = await retry(async () => {
    const result = await model.generateContent(prompt);
    const parsed = extractJsonObject(result.response.text());
    return {
      ta: String(parsed.ta || '').trim(),
      hi: String(parsed.hi || '').trim(),
    };
  });

  return {
    ta: output.ta || text,
    hi: output.hi || text,
  };
}

async function translateToAllLanguages(inputText, baseLanguage) {
  const text = String(inputText || '').trim();
  if (!text) {
    return { en: '', ta: '', hi: '' };
  }

  const model = getGeminiClient();
  const prompt = [
    'Translate the following into English, Tamil, and Hindi.',
    'Keep the meaning clear and practical for farmers.',
    'Return ONLY valid JSON in this format:',
    '{"en":"...","ta":"...","hi":"..."}',
    '',
    `Source language: ${baseLanguage}`,
    `Text: ${text}`,
  ].join('\n');

  const output = await retry(async () => {
    const result = await model.generateContent(prompt);
    const parsed = extractJsonObject(result.response.text());
    return {
      en: String(parsed.en || '').trim(),
      ta: String(parsed.ta || '').trim(),
      hi: String(parsed.hi || '').trim(),
    };
  });

  const source = String(baseLanguage || 'en').trim().toLowerCase();
  if (source === 'ta' && !output.ta) output.ta = text;
  if (source === 'hi' && !output.hi) output.hi = text;
  if (source === 'en' && !output.en) output.en = text;

  const fallback = output.en || output.ta || output.hi || text;
  return {
    en: output.en || fallback,
    ta: output.ta || fallback,
    hi: output.hi || fallback,
  };
}

function isTranslatedMap(value) {
  return Boolean(
    value &&
      typeof value === 'object' &&
      !Array.isArray(value) &&
      typeof value.en === 'string' &&
      typeof value.ta === 'string' &&
      typeof value.hi === 'string',
  );
}

exports.translateEquipmentFields = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const baseLanguage = String(data?.baseLanguage || 'en')
      .trim()
      .toLowerCase();
    const title = String(data?.title || '').trim();
    const description = String(data?.description || '').trim();
    const category = String(data?.category || '').trim();

    if (!title || !description || !category) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'title, description, and category are required',
      );
    }

    const [titleMap, descriptionMap, categoryMap] = await Promise.all([
      translateToAllLanguages(title, baseLanguage),
      translateToAllLanguages(description, baseLanguage),
      translateToAllLanguages(category, baseLanguage),
    ]);

    return {
      title: titleMap,
      description: descriptionMap,
      category: categoryMap,
    };
  });

exports.translateEquipmentData = functions
  .runWith({ timeoutSeconds: 540, memory: '1GB' })
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    if (!context.auth || context.auth.token?.admin !== true) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin access required to run data migration',
      );
    }

    let collectionName = String(data?.collection || '').trim();
    if (!collectionName) {
      const equipmentsProbe = await db
        .collection('equipments')
        .limit(1)
        .get();
      collectionName = equipmentsProbe.empty ? 'equipment' : 'equipments';
    }

    const snapshot = await db.collection(collectionName).get();
    let processed = 0;
    let translated = 0;
    let skipped = 0;
    let failed = 0;

    for (const doc of snapshot.docs) {
      processed += 1;
      const row = doc.data() || {};

      const titleRaw = row.title;
      const descriptionRaw = row.description;
      const categoryRaw = row.category;

      const alreadyDone =
        isTranslatedMap(titleRaw) &&
        isTranslatedMap(descriptionRaw) &&
        isTranslatedMap(categoryRaw);

      if (alreadyDone) {
        skipped += 1;
        continue;
      }

      try {
        const titleMap = normalizeLangMap(
          titleRaw,
          String(row.equipmentName || ''),
        );
        const descriptionMap = normalizeLangMap(descriptionRaw, '');
        const categoryMap = normalizeLangMap(categoryRaw, 'General');

        const translatedTitle = isTranslatedMap(titleRaw)
          ? titleMap
          : {
              en: titleMap.en,
              ...(await translateSingleText(titleMap.en)),
            };

        const translatedDescription = isTranslatedMap(descriptionRaw)
          ? descriptionMap
          : {
              en: descriptionMap.en,
              ...(await translateSingleText(descriptionMap.en)),
            };

        const translatedCategory = isTranslatedMap(categoryRaw)
          ? categoryMap
          : {
              en: categoryMap.en,
              ...(await translateSingleText(categoryMap.en)),
            };

        await doc.ref.update({
          title: {
            en: translatedTitle.en,
            ta: translatedTitle.ta || translatedTitle.en,
            hi: translatedTitle.hi || translatedTitle.en,
          },
          description: {
            en: translatedDescription.en,
            ta: translatedDescription.ta || translatedDescription.en,
            hi: translatedDescription.hi || translatedDescription.en,
          },
          category: {
            en: translatedCategory.en,
            ta: translatedCategory.ta || translatedCategory.en,
            hi: translatedCategory.hi || translatedCategory.en,
          },
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        translated += 1;
      } catch (error) {
        failed += 1;
        functions.logger.error('Failed translating equipment doc', {
          docId: doc.id,
          error: String(error),
        });
      }
    }

    return {
      collection: collectionName,
      processed,
      translated,
      skipped,
      failed,
    };
  });
