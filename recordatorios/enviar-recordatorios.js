const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { Resend } = require('resend');

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
const resendApiKey = process.env.RESEND_API_KEY;
const correoPrueba = process.env.TEST_EMAIL;
const permitirPrueba = process.env.SEND_TEST_EMAIL === 'true';

if (!serviceAccountJson) {
  throw new Error('Falta configurar FIREBASE_SERVICE_ACCOUNT.');
}

initializeApp({
  credential: cert(JSON.parse(serviceAccountJson)),
});

const db = getFirestore();

function obtenerInicioDiaColombia() {
  const partes = Object.fromEntries(
    new Intl.DateTimeFormat('en-CA', {
      timeZone: 'America/Bogota',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    })
      .formatToParts(new Date())
      .map(({ type, value }) => [type, value])
  );

  return new Date(Date.UTC(
    Number(partes.year),
    Number(partes.month) - 1,
    Number(partes.day),
    5, 0, 0, 0
  ));
}

function fechaColombia(fecha) {
  return new Intl.DateTimeFormat('es-CO', {
    timeZone: 'America/Bogota',
    dateStyle: 'long',
  }).format(fecha);
}

async function consultarCuotasPendientes() {
  const hoy = obtenerInicioDiaColombia();
  const limite = new Date(hoy);

  limite.setUTCDate(limite.getUTCDate() + 20);
  limite.setUTCHours(4, 59, 59, 999);

  console.log('Inicio del rango:', hoy.toISOString());
  console.log('Fin del rango:', limite.toISOString());

  const snapshot = await db
    .collection('cuotas')
    .where('estado', '==', 'Pendiente')
    .where('fechaVencimiento', '>=', Timestamp.fromDate(hoy))
    .where('fechaVencimiento', '<=', Timestamp.fromDate(limite))
    .get();

  console.log(`Cuotas encontradas: ${snapshot.size}`);

  if (permitirPrueba && (!resendApiKey || !correoPrueba)) {
    throw new Error('Falta RESEND_API_KEY o TEST_EMAIL.');
  }

  const resend = permitirPrueba ? new Resend(resendApiKey) : null;

  for (const doc of snapshot.docs) {
    const cuota = doc.data();

    if (cuota.recordatorioEnviado === true) {
      console.log(`Cuota ${doc.id}: ya figura como notificada.`);
      continue;
    }

    if (!cuota.idCliente) {
      console.log(`Cuota ${doc.id}: falta idCliente.`);
      continue;
    }

    const clienteDoc = await db.collection('clientes').doc(cuota.idCliente).get();

    if (!clienteDoc.exists) {
      console.log(`Cuota ${doc.id}: cliente no encontrado.`);
      continue;
    }

    const cliente = clienteDoc.data();
    const vencimiento = cuota.fechaVencimiento.toDate();
    const numeroCuota = cuota.numeroCuota ?? 'No especificado';
    const valor = Number(cuota.valorCuota);

    const valorTexto = Number.isFinite(valor)
      ? valor.toLocaleString('es-CO', {
          style: 'currency',
          currency: 'COP',
          maximumFractionDigits: 0,
        })
      : 'Consultar en Cobramzas';

    console.log('Cuota preparada:', {
      idCuota: doc.id,
      nombre: cliente.nombreCompleto || 'Cliente',
      correoRegistrado: cliente.correoElectronico ? 'Sí' : 'No',
      numeroCuota,
      fechaVencimiento: fechaColombia(vencimiento),
      valor: valorTexto,
    });

    if (!resend) {
      console.log('Modo simulación: no se envió correo ni se modificó Firestore.');
      continue;
    }

    if (!cliente.correoElectronico) {
      console.log(`Cuota ${doc.id}: cliente sin correo registrado.`);
      continue;
    }

    const { data, error } = await resend.emails.send({
      from: 'Cobramzas <onboarding@resend.dev>',
      to: [correoPrueba],
      subject: `Prueba Cobramzas - Cuota ${numeroCuota}`,
      text: [
        'Correo de demostración de Cobramzas.',
        '',
        `Cliente de referencia: ${cliente.nombreCompleto || 'Cliente'}`,
        `Número de cuota: ${numeroCuota}`,
        `Valor: ${valorTexto}`,
        `Fecha de vencimiento: ${fechaColombia(vencimiento)}`,
        '',
        'Este mensaje se envió al correo autorizado de prueba.',
        'No se ha notificado al cliente ni se ha modificado su cuota.',
      ].join('\n'),
    });

    if (error) {
      console.error(`Error enviando prueba para cuota ${doc.id}:`, error);
      continue;
    }

    console.log(`Resend aceptó la prueba para cuota ${doc.id}. ID: ${data?.id}`);
  }

  console.log('Proceso finalizado.');
}

consultarCuotasPendientes().catch((error) => {
  console.error('Error consultando las cuotas:', error);
  process.exitCode = 1;
});
