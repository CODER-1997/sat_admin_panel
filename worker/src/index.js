// SAT platforma uchun Cloudflare R2 "darvoza" (Worker).
//
//  GET/HEAD /files/<key>        public/... -> hamma; qolgani -> tizimga kirgan foydalanuvchi (Range qo'llanadi)
//  DELETE   /files/<key>        faqat admin
//  PUT      /upload?key=...     faqat admin (kichik fayllar)
//  POST     /multipart/create   faqat admin (katta fayllar: video)
//  PUT      /multipart/part
//  POST     /multipart/complete
//  POST     /multipart/abort
//
// Foydalanuvchi Firebase ID token bilan keladi (Authorization: Bearer ...).
// Admin ekanligi Firestore'dagi users/{uid}.role == "admin" orqali tekshiriladi.

import { createRemoteJWKSet, jwtVerify } from 'jose';

const JWKS = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'),
);

const ROLE_TTL_MS = 5 * 60 * 1000;
const roleCache = new Map(); // uid -> { role, exp }

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function corsHeaders(env) {
  return {
    'Access-Control-Allow-Origin': env.ALLOWED_ORIGIN || '*',
    'Access-Control-Allow-Methods': 'GET,HEAD,PUT,POST,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization,Content-Type,Range',
    'Access-Control-Expose-Headers': 'Content-Range,Accept-Ranges,Content-Length,ETag',
    'Access-Control-Max-Age': '86400',
  };
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  });
}

function bearer(request) {
  const h = request.headers.get('Authorization') || '';
  return h.startsWith('Bearer ') ? h.slice(7).trim() : null;
}

async function authenticate(request, env) {
  const token = bearer(request);
  if (!token) throw new HttpError(401, 'Tizimga kiring');
  try {
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
      audience: env.FIREBASE_PROJECT_ID,
    });
    if (!payload.sub) throw new Error('no sub');
    return { uid: payload.sub, token };
  } catch (e) {
    throw new HttpError(401, 'Token yaroqsiz yoki muddati tugagan');
  }
}

async function getRole(user, env) {
  const cached = roleCache.get(user.uid);
  if (cached && cached.exp > Date.now()) return cached.role;

  const url =
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}` +
    `/databases/(default)/documents/users/${encodeURIComponent(user.uid)}`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${user.token}` } });
  let role = 'none';
  if (res.ok) {
    const doc = await res.json();
    role = doc?.fields?.role?.stringValue || 'student';
  }
  roleCache.set(user.uid, { role, exp: Date.now() + ROLE_TTL_MS });
  return role;
}

async function requireAdmin(request, env) {
  const user = await authenticate(request, env);
  const role = await getRole(user, env);
  if (role !== 'admin') throw new HttpError(403, 'Faqat admin uchun');
  return user;
}

function cleanKey(raw) {
  if (!raw) throw new HttpError(400, 'key kerak');
  const parts = raw.split('/').map((p) => decodeURIComponent(p));
  if (parts.some((p) => p === '' || p === '.' || p === '..')) {
    throw new HttpError(400, "Noto'g'ri key");
  }
  return parts.join('/');
}

function keyFromQuery(url) {
  const k = url.searchParams.get('key');
  if (!k) throw new HttpError(400, 'key kerak');
  return cleanKey(k);
}

async function serveFile(request, env, key) {
  if (!key.startsWith('public/')) {
    await authenticate(request, env);
  }

  const isHead = request.method === 'HEAD';
  const object = isHead
    ? await env.BUCKET.head(key)
    : await env.BUCKET.get(key, { range: request.headers });
  if (!object) throw new HttpError(404, 'Fayl topilmadi');

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('ETag', object.httpEtag);
  headers.set('Accept-Ranges', 'bytes');
  headers.set(
    'Cache-Control',
    key.startsWith('public/') ? 'public, max-age=31536000, immutable' : 'private, max-age=3600',
  );

  let status = 200;
  if (!isHead && object.range) {
    const r = object.range;
    let start;
    let end;
    if ('suffix' in r) {
      start = object.size - r.suffix;
      end = object.size - 1;
    } else {
      start = r.offset ?? 0;
      end = start + (r.length ?? object.size - start) - 1;
    }
    headers.set('Content-Range', `bytes ${start}-${end}/${object.size}`);
    headers.set('Content-Length', String(end - start + 1));
    status = 206;
  } else {
    headers.set('Content-Length', String(object.size));
  }

  return new Response(isHead ? null : object.body, { status, headers });
}

async function route(request, env) {
  const url = new URL(request.url);
  const path = url.pathname;
  const method = request.method;

  if (path === '/') return json({ ok: true, service: 'sat-storage' });

  if (path.startsWith('/files/')) {
    const key = cleanKey(path.slice('/files/'.length));
    if (method === 'GET' || method === 'HEAD') return serveFile(request, env, key);
    if (method === 'DELETE') {
      await requireAdmin(request, env);
      await env.BUCKET.delete(key);
      return json({ ok: true });
    }
  }

  if (path === '/upload' && method === 'PUT') {
    await requireAdmin(request, env);
    const key = keyFromQuery(url);
    if (!request.body) throw new HttpError(400, "Fayl bo'sh");
    await env.BUCKET.put(key, request.body, {
      httpMetadata: {
        contentType: request.headers.get('Content-Type') || 'application/octet-stream',
      },
    });
    return json({ key });
  }

  if (path === '/multipart/create' && method === 'POST') {
    await requireAdmin(request, env);
    const key = keyFromQuery(url);
    const contentType = url.searchParams.get('contentType') || 'application/octet-stream';
    const mp = await env.BUCKET.createMultipartUpload(key, {
      httpMetadata: { contentType },
    });
    return json({ key, uploadId: mp.uploadId });
  }

  if (path === '/multipart/part' && method === 'PUT') {
    await requireAdmin(request, env);
    const key = keyFromQuery(url);
    const uploadId = url.searchParams.get('uploadId');
    const part = parseInt(url.searchParams.get('part') || '', 10);
    if (!uploadId || !part) throw new HttpError(400, 'uploadId va part kerak');
    if (!request.body) throw new HttpError(400, "Bo'lak bo'sh");
    const mp = env.BUCKET.resumeMultipartUpload(key, uploadId);
    const uploaded = await mp.uploadPart(part, request.body);
    return json({ partNumber: uploaded.partNumber, etag: uploaded.etag });
  }

  if (path === '/multipart/complete' && method === 'POST') {
    await requireAdmin(request, env);
    const key = keyFromQuery(url);
    const uploadId = url.searchParams.get('uploadId');
    if (!uploadId) throw new HttpError(400, 'uploadId kerak');
    const body = await request.json();
    const parts = (body.parts || [])
      .map((p) => ({ partNumber: Number(p.partNumber), etag: String(p.etag) }))
      .sort((a, b) => a.partNumber - b.partNumber);
    const mp = env.BUCKET.resumeMultipartUpload(key, uploadId);
    await mp.complete(parts);
    return json({ key });
  }

  if (path === '/multipart/abort' && method === 'POST') {
    await requireAdmin(request, env);
    const key = keyFromQuery(url);
    const uploadId = url.searchParams.get('uploadId');
    if (!uploadId) throw new HttpError(400, 'uploadId kerak');
    await env.BUCKET.resumeMultipartUpload(key, uploadId).abort();
    return json({ ok: true });
  }

  throw new HttpError(404, 'Topilmadi');
}

export default {
  async fetch(request, env) {
    const cors = corsHeaders(env);
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }

    let response;
    try {
      response = await route(request, env);
    } catch (e) {
      const status = e instanceof HttpError ? e.status : 500;
      const message = e instanceof HttpError ? e.message : 'Server xatosi';
      if (!(e instanceof HttpError)) console.error(e);
      response = json({ error: message }, status);
    }

    const headers = new Headers(response.headers);
    for (const [k, v] of Object.entries(cors)) headers.set(k, v);
    return new Response(response.body, { status: response.status, headers });
  },
};
