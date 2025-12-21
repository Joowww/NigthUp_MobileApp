# PROMPT PARA EL EQUIPO DE BACKEND (FEED DE AMIGOS)

Copia y envía este mensaje a tu equipo o a la IA de backend:

---

### 🎬 REQUERIMIENTOS BACKEND: FEED DE AMIGOS (STYLE TIKTOK)

Hola equipo! He transformado el Feed de Amigos del Frontend en una experiencia vertical (swipe up) con reproducción de video automática y música. Necesitamos que el backend soporte estos nuevos metadatos.

#### 1. ACTUALIZACIÓN DEL MODELO POST
Aseguraos de que el modelo de Post en la DB y el JSON de respuesta incluyan:
- `isVideo`: (Boolean) Indica si el archivo es video o imagen.
- `music`: (Objeto) Con campos `title`, `artist` y `cover`.
- `likesCount`: (Number) Total de likes.
- `commentCount`: (Number) Total de comentarios.

#### 2. ENDPOINT: GET /api/post/feed/friends
Este endpoint ahora debe devolver los posts en el formato arriba mencionado. El frontend ya está usando `PageView.builder` para renderizarlos a pantalla completa.

#### 3. ENDPOINT: POST /api/posts/create
Al crear el post (que ya arreglamos el Multer con el campo `file`), aseguraos de guardar el booleano `isVideo` y el objeto `music` que envía el frontend.

#### 4. INTERACCIONES
Necesitaremos estas rutas para que los botones de la derecha funcionen:
- `POST /api/post/:id/like`
- `POST /api/post/:id/unlike`

El frontend ya está listo para mostrar los videos en cuanto el servidor los escupa con el flag `isVideo: true`. Avisadme cuando esté desplegado!
