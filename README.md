# 🌱 HydroGrow Pro — Invernadero Inteligente con IoT e IA

### Proyecto Universitario — Universidad Tecnológica de San Juan del Río  
**Carrera:** Desarrollo y Gestión de Software  
**Asignatura:** Desarrollo Móvil Integral  

**Equipo:**  
- José Daniel Cárdenas Rojas — *Scrum Master*  
- Karla Daniela Rosales Reséndiz — *Product Owner*  
- Jesús Amado García Reséndiz — *Developer*  
- Abdías Meraz Alvarado — *Developer*  

**Docente:** Héctor Saldaña Benítez  

---

## 📘 Descripción General

**HydroGrow Pro** es un prototipo de **invernadero inteligente** desarrollado con tecnologías **IoT (Internet of Things)**, **Inteligencia Artificial (IA)** y una **aplicación móvil/web** creada en **Flutter**.  
El sistema permite **monitorear y controlar variables ambientales** como temperatura, humedad, pH, conductividad eléctrica y luz, ofreciendo una solución práctica y accesible para usuarios domésticos y pequeños productores agrícolas.

El proyecto busca facilitar la producción sustentable de alimentos mediante el uso de sensores, automatización y herramientas digitales, promoviendo un consumo responsable y reduciendo el impacto ambiental.

---

## 🌍 Problemática

El modelo agrícola tradicional depende de una producción extensiva que provoca **deforestación, pérdida de biodiversidad y altas emisiones de carbono**.  
Además, la mayoría de los consumidores no tiene control sobre el origen o la calidad de sus alimentos. Intentar cultivar en casa suele requerir **tiempo, conocimientos técnicos y mantenimiento constante**, lo que limita su adopción.

**HydroGrow Pro** surge como una alternativa tecnológica que permite al usuario **automatizar y supervisar su propio cultivo** de forma sencilla, eficiente y sostenible.

---

## 🎯 Objetivo del Proyecto

### Objetivo general
Desarrollar un **prototipo funcional de invernadero inteligente** que integre tecnología IoT, inteligencia artificial y una aplicación móvil/web para el monitoreo y control de variables ambientales.

### Objetivos específicos
- Integrar sensores de humedad, temperatura y luz.  
- Conectar sensores y actuadores mediante **ESP32** y el protocolo **MQTT**.  
- Crear una aplicación con **Flutter** para controlar el riego y visualizar datos en tiempo real.  
- Implementar una **IA básica** para predecir necesidades de riego.  
- Añadir un **CRM** con chatbot/n8n para comunicación entre usuarios y productores.  
- Reducir el consumo de agua y energía mediante automatización.

---

## ⚙️ Alcance del Sistema

- Monitoreo en tiempo real de humedad, temperatura y luz.  
- Control manual o automático del riego mediante la aplicación.  
- Interfaz móvil/web intuitiva desarrollada con Flutter.  
- Análisis básico con IA para optimizar el uso de recursos.  
- Almacenamiento seguro de datos mediante Firebase.  
- Notificaciones y alertas sobre condiciones críticas del cultivo.

---

## 🧩 Arquitectura y Tecnologías

### Arquitectura utilizada: **MVVM (Model-View-ViewModel)**
Este patrón permite una clara separación entre la lógica de negocio, la gestión del estado y la interfaz gráfica, mejorando la escalabilidad y el mantenimiento del sistema.

### Principales componentes
| Área | Tecnología |
|------|-------------|
| **Frontend / App** | Flutter |
| **Backend / Auth** | Firebase Authentication |
| **Base de Datos** | Firestore / Realtime Database |
| **IoT** | ESP32 + MQTT |
| **IA básica** | Algoritmos simples de predicción |
| **Automatización** | n8n |
| **CRM / Notificaciones** | Chatbot + Firebase |
| **Seguridad local** | flutter_secure_storage |

---

## 🔐 Seguridad y Privacidad

El proyecto cumple con las buenas prácticas de seguridad recomendadas por **OWASP Mobile Top 10** y con principios de protección de datos personales:

- **Autenticación segura** con Firebase (correo y contraseña).  
- **Comunicación cifrada** mediante HTTPS/TLS.  
- **Reglas de acceso** basadas en `auth.uid` (cada usuario solo accede a sus propios datos).  
- **Almacenamiento seguro** sin contraseñas ni tokens en texto plano.  
- **Protección de datos** personales con consentimiento informado y minimización de información.  
- **App Check** activado para prevenir accesos no autorizados.

---

## 🔄 Metodología de Desarrollo

El desarrollo se realizó siguiendo la metodología **ágil Scrum**, lo que permitió una gestión flexible y organizada del proyecto.

**Roles:**
- **Scrum Master:** José Daniel Cárdenas Rojas  
- **Product Owner:** Karla Daniela Rosales Reséndiz  
- **Desarrolladores:** Jesús Amado García Reséndiz y Abdías Meraz Alvarado  

**Principales prácticas:**
- **Sprint Planning:** planificación de tareas por iteraciones.  
- **Daily Scrum:** reuniones breves para seguimiento del progreso.  
- **Sprint Review:** revisión de resultados al final de cada ciclo.  
- **Sprint Retrospective:** evaluación de mejoras continuas.

---

## 🤖 Integraciones Clave

- **ESP32 + MQTT:** comunicación en tiempo real entre sensores y aplicación.  
- **Firebase:** autenticación, almacenamiento y sincronización de datos.  
- **IA básica:** análisis de patrones para predicción de riego.  
- **Chatbot / CRM:** soporte interactivo y gestión de usuarios.  
- **n8n:** automatización de tareas y flujos de trabajo.  

---

## 🧪 Pruebas y Validación

Durante el proceso de desarrollo se realizaron pruebas funcionales, de integración y de seguridad:

- Validación de formularios (correo, contraseña y consentimiento).  
- Verificación de autenticación y recuperación de contraseñas.  
- Comunicación segura con Firebase.  
- Restricciones de lectura y escritura por usuario.  
- Almacenamiento local seguro sin datos sensibles.  
- Compilaciones finales optimizadas sin modo depuración.

---

## 🌱 Impacto y Beneficios

HydroGrow Pro promueve el uso responsable de los recursos naturales y el acceso a tecnologías de agricultura inteligente.  
Contribuye a la **reducción de emisiones**, la **optimización del consumo de agua** y el **fomento del autocultivo sostenible**, acercando la innovación tecnológica al ámbito doméstico.

---

## 📄 Licencia

Este proyecto fue desarrollado con fines **académicos y tecnológicos** en la  
**Universidad Tecnológica de San Juan del Río**  
para la materia **Desarrollo Móvil Integral**.

© 2025 — *Equipo HydroGrow Pro*  
Todos los derechos reservados.

---------

