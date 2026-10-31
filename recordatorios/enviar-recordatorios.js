
const { initializeApp, cert } = require('firebase-admin/app');
const {
  getFirestore,
  Timestamp,
} = require('firebase-admin/firestore');

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountJson) {
  throw new Error(
    'Falta configurar el secreto FIREBASE_SERVICE_ACCOUNT.'
  );
}

const serviceAccount = JSON.parse(serviceAccountJson);

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

async function consultarCuotasPendientes() {
  // Obtener la fecha actual en Colombia.
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

  // Inicio del día actual en Colombia (UTC-5).
  const hoy = new Date(Date.UTC(
    Number(partes.year),
    Number(partes.month) - 1,
    Number(partes.day),
    5, 0, 0, 0
  ));

  // Final del día número 20, contando desde hoy.
  const limite = new Date(hoy);
  limite.setUTCDate(limite.getUTCDate() + 20);
  limite.setUTCHours(4, 59, 59, 999);

  // Depuración: mostrar el rango que realmente se consulta.
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

    console.log({
      idCuota: doc.id,
      idCliente: cuota.idCliente,
      idCredito: cuota.idCredito,
      numeroCuota: cuota.numeroCuota,
      valorCuota: cuota.valorCuota,
      fechaVencimiento:
        cuota.fechaVencimiento?.toDate().toISOString(),
      recordatorioEnviado: cuota.recordatorioEnviado,
    });
  }
}

consultarCuotasPendientes()
  .then(() => {
    console.log('Consulta finalizada correctamente.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error consultando las cuotas:', error);
    process.exit(1);
  });
