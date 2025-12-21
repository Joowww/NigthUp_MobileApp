# PROMPT PARA EL EQUIPO DE BACKEND (COPIAR Y PEGAR)

Copia el siguiente bloque y envíalo a tu equipo o a la IA de backend:

---

### REQUERIMIENTOS BACKEND - NIGHTUP POSTS & PROFILE

Hola! He actualizado el Frontend con un sistema de posts (estilo TikTok) y necesitamos los siguientes cambios en el Backend:

#### 1. CORRECCIÓN MULTER (Avatar/Cover)
Tenemos un error de campos desincronizados. El Frontend envía:
- Avatar: campo `avatar`
- Portada: campo `coverPhoto`
Por favor, ajustad Multer para que use estos nombres: `upload.single('avatar')` y `upload.single('coverPhoto')`.

#### 2. PROXY DE MÚSICA (CORS Fix)
Para que la búsqueda de música funcione en Web sin errores de CORS, necesitamos un proxy:
- RUTA: `GET /api/music/search?query=...`
- ACCIÓN: El servidor debe pedir los datos a `https://itunes.apple.com/search?term={query}&limit=20&media=music` y devolverlos al frontend.

#### 3. CREACIÓN DE POSTS
Necesitamos el endpoint para subir el contenido:
- RUTA: `POST /api/posts/create` (Multipart)
- CAMPOS:
  - `file`: El archivo (foto o vídeo).
  - `caption`: Texto del post.
  - `location`: Nombre del sitio.
  - `isVideo`: true si es video, false si es foto.
  - `musicTitle`, `musicArtist`, `musicCover`: Datos de la canción seleccionada.

El frontend ya está listo para enviar estos datos por el puerto 3000 (o el que estéis usando). Avisadme cuando los endpoints estén vivos!
