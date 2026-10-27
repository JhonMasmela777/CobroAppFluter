
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

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
  const hoy = new Date();
  hoy.setHours(0, 0, 0, 0);

  const limite = new Date(hoy);
  limite.setDate(limite.getDate() + 12);
  limite.setHours(23, 59, 59, 999);

  const cuotasSnapshot = await db
    .collection('cuotas')
    .where('estado', '==', 'Pendiente')
    .where('fechaVencimiento', '>=', Timestamp.fromDate(hoy))
    .where('fechaVencimiento', '<=', Timestamp.fromDate(limite))
    .get();

  console.log(`Cuotas pendientes encontradas: ${cuotasSnapshot.size}`);

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


