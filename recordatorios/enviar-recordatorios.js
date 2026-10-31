
const { initializeApp, cert } = require('firebase-admin/app');
const {
  getFirestore,
  Timestamp,
} = require('firebase-admin/firestore');
const { Resend } = require('resend');

// ==========================================
// CONFIGURACIÓN DE FIREBASE
// ==========================================

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountJson) {
  throw new Error('Falta configurar FIREBASE_SERVICE_ACCOUNT.');
}

const serviceAccount = JSON.parse(serviceAccountJson);

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

// ==========================================
// CONFIGURACIÓN DE RESEND
// ==========================================

const apiKey = process.env.RESEND_API_KEY;

if (!apiKey) {
  throw new Error('Falta configurar RESEND_API_KEY.');
}

const resend = new Resend(apiKey);

const correoPrueba = process.env.TEST_EMAIL;

if (!correoPrueba) {
  throw new Error('Falta configurar TEST_EMAIL.');
}

// true = prueba manual
// false = envío automático a clientes
const modoPrueba = process.env.SEND_TEST_EMAIL === 'true';

console.log(
  modoPrueba
    ? 'MODO DE PRUEBA ACTIVADO'
    : 'MODO AUTOMÁTICO ACTIVADO'
);

// ==========================================
// CONSULTAR Y ENVIAR RECORDATORIOS
// ==========================================

async function consultarCuotasPendientes() {
  const ahora = new Date();

  // Obtener la fecha actual en Colombia.
  const partesFecha = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(ahora);

  const partes = Object.fromEntries(
    partesFecha.map(({ type, value }) => [type, value])
  );

  // Inicio del día actual en Colombia.
  const hoy = new Date(Date.UTC(
    Number(partes.year),
    Number(partes.month) - 1,
    Number(partes.day),
    5, 0, 0, 0
  ));

  // Próximos 20 días.
  const limite = new Date(hoy);

  limite.setUTCDate(limite.getUTCDate() + 20);
  limite.setUTCHours(4, 59, 59, 999);

  console.log('Fecha actual en UTC:', ahora.toISOString());
  console.log('Inicio del rango:', hoy.toISOString());
  console.log('Fin del rango:', limite.toISOString());

  // Consultar cuotas pendientes.
  const cuotasSnapshot = await db
    .collection('cuotas')
    .where('estado', '==', 'Pendiente')
    .where('fechaVencimiento', '>=', Timestamp.fromDate(hoy))
    .where('fechaVencimiento', '<=', Timestamp.fromDate(limite))
    .get();

  console.log(
    `Cuotas pendientes encontradas: ${cuotasSnapshot.size}`
  );

  let enviados = 0;
  let omitidos = 0;
  let errores = 0;

  // Procesar cada cuota.
  for (const doc of cuotasSnapshot.docs) {
    const cuota = doc.data();

    try {
      // Evitar duplicar recordatorios.
      if (cuota.recordatorioEnviado === true) {
        console.log(`Cuota ${doc.id}: ya tiene recordatorio enviado.`);
        omitidos++;
        continue;
      }

      if (!cuota.idCliente) {
        console.log(`Cuota ${doc.id}: no tiene idCliente.`);
        omitidos++;
        continue;
      }

      // Buscar al cliente por su ID de documento.
      const clienteDoc = await db
        .collection('clientes')
        .doc(cuota.idCliente)
        .get();

      if (!clienteDoc.exists) {
        console.log(`No existe el cliente de la cuota ${doc.id}.`);
        omitidos++;
        continue;
      }

      const cliente = clienteDoc.data();
      const correoCliente = cliente.correoElectronico;

      if (
        typeof correoCliente !== 'string' ||
        !correoCliente.trim()
      ) {
        console.log(
          `El cliente ${cuota.idCliente} no tiene un correo válido.`
        );
        omitidos++;
        continue;
      }

      // Preparar información de la cuota.
      if (!cuota.fechaVencimiento?.toDate) {
        console.log(`Cuota ${doc.id}: fecha de vencimiento inválida.`);
        omitidos++;
        continue;
      }

      const fechaVencimiento = cuota.fechaVencimiento.toDate();

      const fechaTexto = new Intl.DateTimeFormat('es-CO', {
        timeZone: 'America/Bogota',
        day: '2-digit',
        month: 'long',
        year: 'numeric',
      }).format(fechaVencimiento);

      const valorTexto = new Intl.NumberFormat('es-CO', {
        style: 'currency',
        currency: 'COP',
        maximumFractionDigits: 0,
      }).format(cuota.valorCuota || 0);

      // Elegir destinatario según el modo de ejecución.
      const destinatario = modoPrueba
        ? correoPrueba
        : correoCliente.trim();

      console.log('----------------------------------');
      console.log(`Cuota: ${doc.id}`);
      console.log(`Cliente: ${cuota.idCliente}`);
      console.log(`Destinatario: ${destinatario}`);
      console.log(`Número de cuota: ${cuota.numeroCuota}`);
      console.log(`Valor: ${valorTexto}`);
      console.log(`Vencimiento: ${fechaTexto}`);

      // Enviar correo mediante Resend.
      const { data, error } = await resend.emails.send({
        from: 'Cobramzas <onboarding@resend.dev>',
        to: [destinatario],
        subject: 'Recordatorio de pago - Cobramzas',
        text: [
          'Hola,',
          '',
          'Este es un recordatorio de pago de Cobramzas.',
          '',
          `Número de cuota: ${cuota.numeroCuota ?? 'No disponible'}`,
          `Valor: ${valorTexto}`,
          `Fecha de vencimiento: ${fechaTexto}`,
          '',
          'Por favor, revisa la información de tu obligación.',
          '',
          'Saludos,',
          'Sistema Cobramzas',
        ].join('\n'),
      });

      if (error) {
        console.error(`Resend rechazó la cuota ${doc.id}:`, error);
        errores++;
        continue;
      }

      console.log('Resend aceptó el correo:', data?.id);

      // En modo automático se actualiza Firestore.
      // En modo de prueba no se modifica ningún registro.
      if (!modoPrueba) {
        await doc.ref.update({
          recordatorioEnviado: true,
        });

        console.log(`Cuota ${doc.id} marcada como enviada.`);
      } else {
        console.log(
          'Modo de prueba: Firestore no fue modificado.'
        );
      }

      enviados++;

    } catch (error) {
      console.error(`Error procesando cuota ${doc.id}:`, error);
      errores++;
    }
  }

  console.log('==================================');
  console.log('RESUMEN DEL PROCESO');
  console.log(`Correos aceptados por Resend: ${enviados}`);
  console.log(`Cuotas omitidas: ${omitidos}`);
  console.log(`Errores: ${errores}`);
  console.log('==================================');
}

// ==========================================
// EJECUCIÓN
// ==========================================

consultarCuotasPendientes()
  .then(() => {
    console.log('Proceso de recordatorios finalizado.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en el proceso de recordatorios:', error);
    process.exit(1);
  });
