
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
// PLANTILLA HTML DEL CORREO
// ==========================================

function crearCorreoHTML(cuota, valorTexto, fechaTexto) {
  const numeroCuota = cuota.numeroCuota ?? 'No disponible';

  return `
  <!DOCTYPE html>
  <html lang="es">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recordatorio de pago - Cobra tech</title>
  </head>

  <body style="
    margin: 0;
    padding: 0;
    background-color: #f1f5f3;
    font-family: Arial, Helvetica, sans-serif;
    color: #26352e;
  ">

    <table width="100%" cellpadding="0" cellspacing="0"
      style="background-color: #f1f5f3; padding: 35px 12px;">

      <tr>
        <td align="center">

          <table width="100%" cellpadding="0" cellspacing="0"
            style="
              max-width: 580px;
              background-color: #ffffff;
              border-radius: 16px;
              overflow: hidden;
              box-shadow: 0 5px 20px rgba(0,0,0,0.07);
            ">

            <!-- ENCABEZADO -->
            <tr>
              <td align="center" style="
                background-color: #087f5b;
                padding: 32px 20px;
              ">
                <h1 style="
                  margin: 0;
                  color: #ffffff;
                  font-size: 29px;
                  font-weight: bold;
                  letter-spacing: 1px;
                ">
                  COBRA TECH
                </h1>

                <p style="
                  margin: 9px 0 0;
                  color: #d8fff0;
                  font-size: 14px;
                ">
                  Sistema de gestión de Cobra tech
                </p>
              </td>
            </tr>

            <!-- CONTENIDO -->
            <tr>
              <td style="padding: 35px 30px 20px;">

                <h2 style="
                  margin: 0 0 15px;
                  color: #087f5b;
                  font-size: 23px;
                ">
                  ¡Hola!
                </h2>

                <p style="
                  margin: 0 0 20px;
                  color: #52635a;
                  font-size: 15px;
                  line-height: 1.7;
                ">
                  Te enviamos este mensaje para recordarte que tienes
                  una cuota próxima a vencer. A continuación encontrarás
                  los detalles de tu pago.
                </p>

                <!-- TARJETA DE VALOR -->
                <table width="100%" cellpadding="0" cellspacing="0"
                  style="
                    background-color: #e8f8f0;
                    border: 1px solid #c5ead6;
                    border-radius: 12px;
                  ">
                  <tr>
                    <td align="center" style="padding: 23px 15px;">

                      <p style="
                        margin: 0 0 8px;
                        color: #527263;
                        font-size: 13px;
                      ">
                        VALOR DE LA CUOTA
                      </p>

                      <h1 style="
                        margin: 0;
                        color: #087f5b;
                        font-size: 32px;
                      ">
                        ${valorTexto}
                      </h1>

                    </td>
                  </tr>
                </table>

                <!-- DETALLES -->
                <h3 style="
                  margin: 28px 0 15px;
                  color: #26352e;
                  font-size: 17px;
                ">
                  Detalles de tu pago
                </h3>

                <table width="100%" cellpadding="0" cellspacing="0"
                  style="font-size: 14px;">

                  <tr>
                    <td style="
                      padding: 12px 0;
                      color: #718078;
                      border-bottom: 1px solid #edf1ee;
                    ">
                      Número de cuota
                    </td>

                    <td align="right" style="
                      padding: 12px 0;
                      color: #26352e;
                      font-weight: bold;
                      border-bottom: 1px solid #edf1ee;
                    ">
                      ${numeroCuota}
                    </td>
                  </tr>

                  <tr>
                    <td style="
                      padding: 12px 0;
                      color: #718078;
                      border-bottom: 1px solid #edf1ee;
                    ">
                      Fecha de vencimiento
                    </td>

                    <td align="right" style="
                      padding: 12px 0;
                      color: #d97706;
                      font-weight: bold;
                      border-bottom: 1px solid #edf1ee;
                    ">
                      ${fechaTexto}
                    </td>
                  </tr>

                  <tr>
                    <td style="
                      padding: 12px 0;
                      color: #718078;
                    ">
                      Estado
                    </td>

                    <td align="right" style="
                      padding: 12px 0;
                      color: #d97706;
                      font-weight: bold;
                    ">
                      Pendiente
                    </td>
                  </tr>

                </table>

                <!-- AVISO -->
                <table width="100%" cellpadding="0" cellspacing="0"
                  style="
                    margin-top: 25px;
                    background-color: #fff8e8;
                    border-left: 4px solid #e9a23b;
                  ">
                  <tr>
                    <td style="
                      padding: 15px;
                      color: #76551d;
                      font-size: 13px;
                      line-height: 1.6;
                    ">
                      <strong>Importante:</strong>
                      Recuerda realizar tu pago oportunamente para
                      mantener tus cuotas al día.
                    </td>
                  </tr>
                </table>

                <p style="
                  margin: 25px 0 10px;
                  color: #52635a;
                  font-size: 14px;
                  line-height: 1.6;
                ">
                  Gracias por confiar en nosotros.
                  Si ya realizaste tu pago, puedes hacer caso omiso
                  de este recordatorio.
                </p>

                <p style="
                  margin: 20px 0 5px;
                  color: #26352e;
                  font-size: 14px;
                ">
                  Cordialmente,
                </p>

                <p style="
                  margin: 0 0 15px;
                  color: #087f5b;
                  font-size: 16px;
                  font-weight: bold;
                ">
                  Equipo Cobra tech
                </p>

              </td>
            </tr>

            <!-- PIE DE CORREO -->
            <tr>
              <td align="center" style="
                background-color: #f7faf8;
                padding: 22px 20px;
                border-top: 1px solid #edf1ee;
              ">

                <p style="
                  margin: 0 0 7px;
                  color: #087f5b;
                  font-size: 15px;
                  font-weight: bold;
                ">
                  COBRA TECH
                </p>

                <p style="
                  margin: 0;
                  color: #89968f;
                  font-size: 11px;
                  line-height: 1.6;
                ">
                  Mensaje automático generado por el sistema de cobranzas.
                  <br>
                  Por favor, no respondas directamente a este correo.
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
  console.log('Inicio del rango:', hoy.toISOString());
  console.log('Fin del rango:', limite.toISOString());

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

  for (const doc of cuotasSnapshot.docs) {
    const cuota = doc.data();

    try {
      if (cuota.recordatorioEnviado === true) {
        console.log(`Cuota ${doc.id}: recordatorio ya enviado.`);
        omitidos++;
        continue;
      }

      if (!cuota.idCliente) {
        console.log(`Cuota ${doc.id}: no tiene idCliente.`);
        omitidos++;
        continue;
      }

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

      const { data, error } = await resend.emails.send({
        from: 'Cobra tech <onboarding@resend.dev>',
        to: [destinatario],
        subject: 'Recordatorio de pago - Cobra tech',

        // Versión HTML con diseño.
        html: crearCorreoHTML(cuota, valorTexto, fechaTexto),

        // Versión de texto para clientes de correo que no muestran HTML.
        text: [
          'Hola,',
          '',
          'Este es un recordatorio de pago de Cobra tech.',
          '',
          `Número de cuota: ${cuota.numeroCuota ?? 'No disponible'}`,
          `Valor: ${valorTexto}`,
          `Fecha de vencimiento: ${fechaTexto}`,
          'Estado: Pendiente',
          '',
          'Recuerda realizar tu pago oportunamente.',
          '',
          'Saludos,',
          'Equipo Cobra tech',
        ].join('\n'),
      });

      if (error) {
        console.error(`Resend rechazó la cuota ${doc.id}:`, error);
        errores++;
        continue;
      }

      console.log('Resend aceptó el correo:', data?.id);

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

  if (errores > 0) {
    process.exitCode = 1;
  }
}

// ==========================================
// EJECUCIÓN
// ==========================================

consultarCuotasPendientes()
  .then(() => {
    console.log('Proceso de recordatorios finalizado.');
  })
  .catch((error) => {
    console.error('Error en el proceso de recordatorios:', error);
    process.exitCode = 1;
  });
