
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
// BUSCAR CLIENTE MEDIANTE IDCLIENTE
// ==========================================

async function buscarCliente(idCliente) {

  // Primera búsqueda: UID como ID del documento.
  let clienteDoc = await db
    .collection('clientes')
    .doc(idCliente)
    .get();

  if (clienteDoc.exists) {
    return clienteDoc;
  }

  // Segunda búsqueda: UID almacenado en el campo uid.
  let resultado = await db
    .collection('clientes')
    .where('uid', '==', idCliente)
    .limit(1)
    .get();

  if (!resultado.empty) {
    return resultado.docs[0];
  }

  // Tercera búsqueda: UID almacenado en el campo idCliente.
  resultado = await db
    .collection('clientes')
    .where('idCliente', '==', idCliente)
    .limit(1)
    .get();

  if (!resultado.empty) {
    return resultado.docs[0];
  }

  return null;
}

// ==========================================
// BUSCAR CRÉDITOS MEDIANTE IDCLIENTE
// ==========================================

async function buscarCreditos(idCliente) {
  return await db
    .collection('creditos')
    .where('idCliente', '==', idCliente)
    .get();
}

// ==========================================
// PROTEGER TEXTO PARA HTML
// ==========================================

function escaparHTML(texto) {
  return String(texto ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// ==========================================
// DISEÑO HTML DEL CORREO
// ==========================================

function crearCorreoHTML(cuota, valorTexto, fechaTexto, nombreCliente) {

  return `
  <!DOCTYPE html>
  <html lang="es">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recordatorio de pago</title>
  </head>

  <body style="margin:0;padding:0;background-color:#f3f6f4;font-family:Arial,sans-serif;">

    <table width="100%" cellpadding="0" cellspacing="0"
      style="padding:35px 12px;background-color:#f3f6f4;">

      <tr>
        <td align="center">

          <table width="100%" cellpadding="0" cellspacing="0"
            style="max-width:580px;background-color:#ffffff;border-radius:14px;overflow:hidden;">

            <tr>
              <td style="background-color:#176b45;padding:30px;text-align:center;">

                <h1 style="margin:0;color:#ffffff;font-size:28px;">
                  COBRAMZAS
                </h1>

                <p style="margin:8px 0 0;color:#e5f5eb;font-size:14px;">
                  Recordatorios de pago
                </p>

              </td>
            </tr>

            <tr>
              <td style="padding:32px 28px;">

                <h2 style="color:#24352b;font-size:21px;margin-top:0;">
                  Hola, ${escaparHTML(nombreCliente)}
                </h2>

                <p style="color:#59665e;font-size:15px;line-height:1.7;">
                  Te enviamos este mensaje para recordarte que tienes una cuota pendiente de pago.
                  A continuación encontrarás los detalles:
                </p>

                <table width="100%" cellpadding="0" cellspacing="0"
                  style="background-color:#f2f8f4;border-radius:10px;padding:20px;margin:22px 0;">

                  <tr>
                    <td style="padding:9px 0;color:#66736b;font-size:14px;">
                      Número de cuota
                    </td>

                    <td align="right" style="padding:9px 0;color:#24352b;font-weight:bold;">
                      ${escaparHTML(cuota.numeroCuota ?? 'No disponible')}
                    </td>
                  </tr>

                  <tr>
                    <td style="padding:9px 0;color:#66736b;font-size:14px;">
                      Valor a pagar
                    </td>

                    <td align="right" style="padding:9px 0;color:#176b45;font-size:18px;font-weight:bold;">
                      ${escaparHTML(valorTexto)}
                    </td>
                  </tr>

                  <tr>
                    <td style="padding:9px 0;color:#66736b;font-size:14px;">
                      Fecha de vencimiento
                    </td>

                    <td align="right" style="padding:9px 0;color:#24352b;font-weight:bold;">
                      ${escaparHTML(fechaTexto)}
                    </td>
                  </tr>

                  <tr>
                    <td style="padding:9px 0;color:#66736b;font-size:14px;">
                      Estado
                    </td>

                    <td align="right" style="padding:9px 0;color:#d97706;font-weight:bold;">
                      Pendiente
                    </td>
                  </tr>

                </table>

                <p style="color:#59665e;font-size:14px;line-height:1.7;">
                  Te invitamos a realizar tu pago oportunamente para mantener tus obligaciones al día.
                </p>

                <p style="color:#24352b;font-size:15px;margin-top:28px;">
                  Cordialmente,<br>
                  <strong>Equipo Cobramzas</strong>
                </p>

              </td>
            </tr>

            <tr>
              <td style="background-color:#f3f6f4;padding:20px;text-align:center;">

                <p style="margin:0;color:#78847c;font-size:12px;line-height:1.6;">
                  Este es un mensaje automático de recordatorio de pago.
                  Por favor, no respondas a este correo.
                </p>

                <p style="margin:10px 0 0;color:#176b45;font-size:13px;font-weight:bold;">
                  COBRAMZAS
                </p>

              </td>
            </tr>

          </table>

        </td>
      </tr>

    </table>

  </body>
  </html>
  `;
}

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

      // Obtener ID del cliente.
      const idCliente = cuota.idCliente;

      if (!idCliente) {
        console.log(`Cuota ${doc.id}: no tiene idCliente.`);
        omitidos++;
        continue;
      }

      console.log('----------------------------------');
      console.log(`Cuota: ${doc.id}`);
      console.log(`ID Cliente: ${idCliente}`);

      // Buscar cliente por idCliente.
      const clienteDoc = await buscarCliente(idCliente);

      if (!clienteDoc) {
        console.log(`No se encontró el cliente: ${idCliente}`);
        omitidos++;
        continue;
      }

      const cliente = clienteDoc.data();

      console.log('Cliente encontrado:', clienteDoc.id);

      // Obtener correo electrónico.
      const correoCliente = cliente.correoElectronico;

      if (
        typeof correoCliente !== 'string' ||
        !correoCliente.trim()
      ) {
        console.log(
          `El cliente ${idCliente} no tiene un correo válido.`
        );
        omitidos++;
        continue;
      }

      // Buscar créditos mediante idCliente.
      const creditosSnapshot = await buscarCreditos(idCliente);

      console.log(
        `Créditos encontrados para el cliente: ${creditosSnapshot.size}`
      );

      // La cuota ya tiene su propio idCliente.
      // La búsqueda de créditos es de verificación.
      if (creditosSnapshot.empty) {
        console.log(
          `Advertencia: no se encontraron créditos para ${idCliente}.`
        );
      }

      // Verificar fecha de vencimiento.
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

      const nombreCliente =
        cliente.nombre ||
        cliente.nombreCompleto ||
        'Cliente';

      // Elegir destinatario según el modo.
      const destinatario = modoPrueba
        ? correoPrueba
        : correoCliente.trim();

      console.log(`Destinatario: ${destinatario}`);
      console.log(`Número de cuota: ${cuota.numeroCuota}`);
      console.log(`Valor: ${valorTexto}`);
      console.log(`Vencimiento: ${fechaTexto}`);

      // Preparar mensaje de correo.
      const { data, error } = await resend.emails.send({

        from: 'Cobramzas <onboarding@resend.dev>',

        to: [destinatario],

        subject: 'Recordatorio de pago - Cobramzas',

        text: [
          `Hola ${nombreCliente},`,
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
          'Equipo Cobramzas',
        ].join('\n'),

        html: crearCorreoHTML(
          cuota,
          valorTexto,
          fechaTexto,
          nombreCliente
        ),
      });

      if (error) {
        console.error(
          `Resend rechazó la cuota ${doc.id}:`,
          error
        );

        errores++;
        continue;
      }

      console.log('Resend aceptó el correo:', data?.id);

      // Actualizar Firestore solamente en modo automático.
      if (!modoPrueba) {

        await doc.ref.update({
          recordatorioEnviado: true,
        });

        console.log(
          `Cuota ${doc.id} marcada como enviada.`
        );

      } else {

        console.log(
          'Modo de prueba: Firestore no fue modificado.'
        );
      }

      enviados++;

    } catch (error) {

      console.error(
        `Error procesando cuota ${doc.id}:`,
        error
      );

      errores++;
    }
  }

  // Resumen.
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
