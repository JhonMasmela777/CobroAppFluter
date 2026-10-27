const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountJson) {
  throw new Error('Falta configurar FIREBASE_SERVICE_ACCOUNT.');
}

const serviceAccount = JSON.parse(serviceAccountJson);

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

async function diagnosticarCuotas() {
  console.log('Proyecto Firebase:', serviceAccount.project_id);
  console.log('Consultando la colección completa: cuotas');

  const snapshot = await db.collection('cuotas').get();

  console.log('Total de documentos en cuotas:', snapshot.size);

  for (const doc of snapshot.docs) {
    const cuota = doc.data();
    const fecha = cuota.fechaVencimiento;

    console.log({
      documento: doc.id,
      estado: cuota.estado,
      tipoFecha: fecha instanceof Timestamp ? 'Timestamp' : typeof fecha,
      fechaVencimiento:
        fecha && typeof fecha.toDate === 'function'
          ? fecha.toDate().toISOString()
          : String(fecha),
    });
  }
}

diagnosticarCuotas()
  .then(() => {
    console.log('Diagnóstico terminado.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error en el diagnóstico:', error);
    process.exit(1);
  });
