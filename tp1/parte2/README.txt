Clase 3 - TP 1 - Ayudantes, Parte 1
La idea de este TP en clase es poner en práctica
Nuestro entendimiento del event loop
Diseñar empleando CPS
IO async.
Utilizaremos NodeJS, pero evitaremos caer en sus malas prácticas de manejo de error.
Descripción del Problema

Tenemos una lista de correos utilizada para responder preguntas sobre una materia. Tenemos dos roles bien diferenciados:
Alumnos que hacen preguntas y leen respuestas
Docentes que "compiten" por responder
Queremos hacer una prueba de concepto de una arquitectura event-driven HTTP utilizando NodeJS. Por ello sólo modelaremos la comunicación HTTP, y los aspectos más importantes del procesamiento. No nos ocuparemos de implementar
persistencia
presentación
seguridad
Primera iteración

Escribir la implementación más simple que permita:
A un alumno escribir una consulta en la lista. La consulta es recibida por todos los demás alumnos, y todos los docentes. La consulta viene junto con el remitente.
A los docentes responder la pregunta. La respuesta le llega a todos. Un docente no puede escribir espontáneamente a la lista, debe hacerlo siempre con una referencia a la pregunta.
Y escribir los clientes necesarios para probar funcionalmente la arquitectura. Sugerencia: escribir dos procesos node que representen a alumnos y docentes, que pregunten y respondan al azar.
Segunda iteración

Cuando un docente empieza a escribir una respuesta los demás docentes deben ser notificados.
Tercera iteracion

Una vez que un docente haya respondido, no se permitirá que otro docente responda; respuestas posteriores deberán ser filtradas.
Para pensar: ¿qué complejidades introduce este requerimiento a la arquitectura?
