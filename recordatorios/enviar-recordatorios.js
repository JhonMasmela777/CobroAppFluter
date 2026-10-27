const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccountJson) {
  throw new Error('Falta configurar FIREBASE_SERVICE_ACCOUNT.');
}

initializeApp({
  credential: cert(JSON.parse(serviceAccountJson)),
});

const db = getFirestore();

async function consultarCuotasPendientes() {
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

  const hoy = new Date(Date.UTC(
    Number(partes.year),
    Number(partes.month) - 1,
    Number(partes.day),
    5, 0, 0, 0
  ));

  const limite = new Date(hoy);
  limite.setUTCDate(limite.getUTCDate() + 20);
  limite.setUTCHours(4, 59, 59, 999);

  console.log('Inicio UTC:', hoy.toISOString());
  console.log('Límite UTC:', limite.toISOString());

  // Prueba primero el estado, sin filtrar por fechas.
  const pendientes = await db
    .collection('cuotas')
    .where('estado', '==', 'Pendiente')
    .get();

  console.log('Cuotas pendientes sin filtro de fechas:', pendientes.size);

  for (const doc of pendientes.docs) {
    const cuota = doc.data();
    const fecha = cuota.fechaVencimiento;

    if (fecha && typeof fecha.toDate === 'function') {
      const vencimiento = fecha.toDate();

      console.log({
        idCuota: doc.id,
        fechaVencimiento: vencimiento.toISOString(),
        dentroDelRango:
          vencimiento >= hoy && vencimiento <= limite,
      });
    } else {
      console.log({
        idCuota: doc.id,
        error: 'fechaVencimiento no es un Timestamp válido',
      });
    }
  }

  const resultado = await db
    .collection('cuotas')
    .where('estado', '==', 'Pendiente')
    .where('fechaVencimiento', '>=', Timestamp.fromDate(hoy))
    .where('fechaVencimiento', '<=', Timestamp.fromDate(limite))
    .get();

  console.log('Cuotas dentro del rango:', resultado.size);
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
