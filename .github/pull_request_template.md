## 🚀 Tipo de Cambio

Por favor, marca el tipo de cambio que tu Pull Request introduce (Ejemplo: fix para correcciones, feat para funcionalidad nueva):

- [ ] ✨ feat: Nueva funcionalidad.
- [ ] 🐛 fix: Corrección de un error (bug).
- [ ] 📝 docs: Cambios en la documentación.
- [ ] 🧹 refactor: Cambio de código que no corrige un error ni añade funcionalidad.
- [ ] 🧪 test: Añadir o corregir tests (pruebas).
- [ ] ⚙ chore: Cambios de mantenimiento (ej: actualización de dependencias, configuración de CI).

---

## 📝 Descripción del Cambio

Describe brevemente y de forma clara los cambios que has realizado. Incluye el contexto, similar a la modificación de la etiqueta 'Panel' a 'Panel_prueba' que se realizó para la evidencia[cite: 37, 38].

*(Si aplica) Problema Relacionado:* Cierra #[número_del_issue]

---

## ✅ Checklist de Revisión

Asegúrate de haber completado las siguientes tareas antes de solicitar la revisión.

[cite_start]*El objetivo es mantener la estabilidad del proyecto mediante pruebas automáticas y análisis estáticos[cite: 211].*

### Verificación de CI/Código
- [ ] Mi código sigue las guías de estilo del proyecto (pasa el flutter analyze).
- [ ] He realizado una auto-revisión de mi propio código.
- [ ] He añadido nuevos tests para cubrir esta nueva funcionalidad/corrección (si aplica).
- [ ] Los tests unitarios existentes pasan con mis cambios.
- [ ] *El Workflow de CI de GitHub Actions se ejecutó correctamente* y el estado es *Éxito*.

### Funcionalidad y Documentación
- [ ] El cambio no introduce fallos en el funcionamiento general (regresiones).
- [ ] El cambio funciona en al menos una plataforma (Android/iOS/Web).
- [ ] He actualizado la documentación en consecuencia (si aplica).

---

## 🖼 Capturas de Pantalla / Videos (Opcional)

[cite_start]Añade capturas de pantalla o un video corto que muestre los cambios visuales o el funcionamiento de la nueva característica/corrección (Similar a la captura del cambio en VS Code o la comparación en GitHub [cite: 39, 152]).