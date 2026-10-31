
const { initializeApp, cert } = require('firebase-admin/app');
const {
  getFirestore,
  Timestamp,
} = require('firebase-admin/firestore');
const { Resend } = require('resend');

// Configuración de Firebase
const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountJson) {
  throw new Error('Falta configurar FIREBASE_SERVICE_ACCOUNT.');
}

const serviceAccount = JSON.parse(serviceAccountJson);

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

// Configuración de Resend
const apiKey = process.env.RESEND_API_KEY;

if (!apiKey) {
  throw new Error('Falta configurar RESEND_API_KEY.');
}

const resend = new Resend(apiKey);

// Correo autorizado para las pruebas con onboarding@resend.dev
const correoPrueba = process.env.TEST_EMAIL;

if (!correoPrueba) {
  throw new Error('Falta configurar TEST_EMAIL.');
}

async function consultarCuotasPendientes() {
  const ahora = new Date();

  const partesFecha = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(ahora);

  const partes = Object.fromEntries(
    partesFecha.map(({ type, value }) => [type, value])
  );

  const hoy = new Date(Date.UTC(
    Number(partes.year),
    Number(partes.month) - 1,
    Number(partes.day),
    5, 0, 0, 0
  ));

  const limite = new Date(hoy);
  limite.setUTCDate(limite.getUTCDate() + 20);
  limite.setUTCHours(4, 59, 59, 999);

  console.log('Fecha actual en UTC:', ahora.toISOString());
  console.log('Inicio del rango (Colombia):', hoy.toISOString());
  console.log('Fin del rango (Colombia):', limite.toISOString());

  const cuotasSnapshot = await db
    .collection('cuotas')
    .where('estado', '==', 'Pendiente')
    .where('fechaVencimiento', '>=', Timestamp.fromDate(hoy))
    .where('fechaVencimiento', '<=', Timestamp.fromDate(limite))
    .get();

  console.log(
    `Cuotas pendientes encontradas: ${cuotasSnapshot.size}`
  );

  for (const doc of cuotasSnapshot.docs) {
    const cuota = doc.data();

    // Evitar enviar nuevamente un recordatorio ya procesado.
    if (cuota.recordatorioEnviado === true) {
      console.log(`Cuota ${doc.id}: recordatorio ya enviado.`);
      continue;
    }

    try {
      if (!cuota.idCliente) {
        console.log(`Cuota ${doc.id}: no tiene idCliente.`);
        continue;
      }

      // Buscar el cliente mediante el ID del documento.
      const clienteDoc = await db
        .collection('clientes')
        .doc(cuota.idCliente)
        .get();

      if (!clienteDoc.exists) {
        console.log(`No existe el cliente de la cuota ${doc.id}.`);
        continue;
      }

      const cliente = clienteDoc.data();
      const correoCliente = cliente.correoElectronico;

      if (!correoCliente) {
        console.log(`El cliente ${cuota.idCliente} no tiene correo.`);
        continue;
      }

      const fechaVencimiento =
        cuota.fechaVencimiento.toDate();

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

      console.log(`Procesando cuota ${doc.id}.`);
      console.log(`Correo registrado: ${correoCliente}`);

      // En modo de prueba, el correo se envía a TEST_EMAIL.
      // No se envía al correo real del cliente.
      const { data, error } = await resend.emails.send({
        from: 'Cobramzas <onboarding@resend.dev>',
        to: [correoPrueba],
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
        console.error(`Error enviando cuota ${doc.id}:`, error);
        continue;
      }

      console.log('Resend aceptó el correo:', data?.id);

      // Marcar como enviado solamente después de la aceptación.
      await doc.ref.update({
        recordatorioEnviado: true,
      });

      console.log(`Cuota ${doc.id} marcada como enviada.`);
    } catch (error) {
      console.error(`Error procesando cuota ${doc.id}:`, error);
    }
  }
}

consultarCuotasPendientes()
  .then(() => {
    console.log('Proceso de recordatorios finalizado.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en el proceso de recordatorios:', error);
    process.exit(1);
  });
