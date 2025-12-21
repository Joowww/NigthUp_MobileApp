# Documentación para Backend: Implementación de Posts y Feed

Hemos implementado en el Frontend la funcionalidad completa de creación de contenido estilo TikTok/Instagram. Necesitamos que el equipo de Backend habilite la persistencia de estos datos.

## 1. Nuevo Endpoint: Búsqueda de Música (Proxy)
Para evitar errores de **CORS** en la Web, el backend debe actuar como proxy para la API de iTunes.

- **Ruta**: `GET /api/music/search?query=...`
- **Funcionalidad**: Debe llamar a `https://itunes.apple.com/search?term={query}&media=music&limit=20` y devolver el JSON procesado.
- **Campos necesarios**: `title`, `artist`, `coverUrl`, `previewUrl`.

## 2. Nuevo Endpoint: Creación de Post
- **Ruta**: `POST /api/posts/create`
- **Tipo**: `multipart/form-data`
- **Campos**:
  - `file`: (Archivo) Imagen (.jpg/png) o Vídeo (.mp4/webm).
  - `caption`: (String) Descripción del post.
  - `location`: (String) Nombre de la ubicación (ej: "Barcelona").
  - `musicTitle`: (String/Optional) Nombre de la canción.
  - `musicArtist`: (String/Optional) Artista.
  - `musicCover`: (String/Optional) URL de la carátula.
  - `isVideo`: (Boolean) Flag para saber si es vídeo o foto.

## 3. Modelo de Datos (Post)
Sugerencia de campos para la base de datos:
```javascript
{
  user: ObjectId, // Autor del post
  mediaUrl: String, // URL del archivo en S3/Cloudinary/Local
  isVideo: Boolean,
  caption: String,
  location: String,
  music: {
    title: String,
    artist: String,
    coverUrl: String
  },
  likes: [ObjectId],
  comments: [ObjectId],
  createdAt: Date
}
```

## 4. Notas Técnicas del Frontend
- Estamos usando el paquete `camera` para grabar. 
- En Web, los vídeos se graban en formato **Blob/WebM**.
- El nombre del campo para el archivo en el multipart debe ser `file`.
- Al subir fotos de perfil, ya usamos los campos `avatar` y `coverPhoto`.
