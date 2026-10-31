
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
// DISEÑO HTML DEL CORREO
// ==========================================

function crearCorreoHTML(cuota, valorTexto, fechaTexto) {
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
    background-color: #f0f4f2;
    font-family: Arial, Helvetica, sans-serif;
    color: #263b32;
  ">

    <table width="100%" cellpadding="0" cellspacing="0"
      border="0" style="background-color: #f0f4f2; padding: 35px 12px;">

      <tr>
        <td align="center">

          <table width="100%" cellpadding="0" cellspacing="0"
            border="0" style="
              max-width: 580px;
              background-color: #ffffff;
              border-radius: 18px;
              overflow: hidden;
            ">

            <!-- ENCABEZADO -->
            <tr>
              <td align="center" style="
                background-color: #087f5b;
                padding: 35px 20px;
              ">

                <div style="
                  display: inline-block;
                  border: 2px solid #ffffff;
                  border-radius: 12px;
                  padding: 10px 15px;
                  margin-bottom: 12px;
                ">
                  <span style="
                    color: #ffffff;
                    font-size: 25px;
                    font-weight: bold;
                    letter-spacing: 2px;
                  ">
                    COBRA TECH
                  </span>
                </div>

                <p style="
                  margin: 5px 0 0;
                  color: #d7f8e9;
                  font-size: 14px;
                ">
                  Sistema inteligente de gestión de cobranzas
                </p>

              </td>
            </tr>

            <!-- CONTENIDO PRINCIPAL -->
            <tr>
              <td style="padding: 35px 30px 20px;">

                <p style="
                  margin: 0 0 8px;
                  color: #087f5b;
                  font-size: 13px;
                  font-weight: bold;
                  letter-spacing: 1px;
                ">
                  NOTIFICACIÓN DE PAGO
                </p>

                <h1 style="
                  margin: 0 0 16px;
                  color: #263b32;
                  font-size: 25px;
                ">
                  ¡Hola! 👋
                </h1>

                <p style="
                  margin: 0 0 25px;
                  color: #66756d;
                  font-size: 15px;
                  line-height: 1.8;
                ">
                  Queremos recordarte que tienes una cuota próxima
                  a vencer. Aquí encontrarás toda la información
                  correspondiente a tu próximo pago.
                </p>

                <!-- TARJETA DEL VALOR -->
                <table width="100%" cellpadding="0" cellspacing="0"
                  border="0" style="
                    background-color: #e9f8f0;
                    border: 1px solid #c8ead6;
                    border-radius: 15px;
                  ">
                  <tr>
                    <td align="center" style="padding: 27px 15px;">

                      <p style="
                        margin: 0 0 10px;
                        color: #527665;
                        font-size: 12px;
                        font-weight: bold;
                        letter-spacing: 1.5px;
                      ">
                        VALOR DE TU CUOTA
                      </p>

                      <h2 style="
                        margin: 0;
                        color: #087f5b;
                        font-size: 34px;
                        font-weight: bold;
                      ">
                        ${valorTexto}
                      </h2>

                      <p style="
                        margin: 10px 0 0;
                        color: #648675;
                        font-size: 12px;
                      ">
                        Valor expresado en pesos colombianos
                      </p>

                    </td>
                  </tr>
                </table>

                <!-- INFORMACIÓN DE LA CUOTA -->
                <h3 style="
                  margin: 30px 0 15px;
                  color: #263b32;
                  font-size: 17px;
                ">
                  Resumen de tu obligación
                </h3>

                <table width="100%" cellpadding="0" cellspacing="0"
                  border="0" style="
                    border: 1px solid #e8eeea;
                    border-radius: 10px;
                  ">

                  <tr>
                    <td style="
                      padding: 15px;
                      color: #78877f;
                      font-size: 14px;
                      border-bottom: 1px solid #e8eeea;
                    ">
                      Número de cuota
                    </td>

                    <td align="right" style="
                      padding: 15px;
                      color: #263b32;
                      font-size: 14px;
                      font-weight: bold;
                      border-bottom: 1px solid #e8eeea;
                    ">
                      ${cuota.numeroCuota ?? 'No disponible'}
                    </td>
                  </tr>

                  <tr>
                    <td style="
                      padding: 15px;
                      color: #78877f;
                      font-size: 14px;
                      border-bottom: 1px solid #e8eeea;
                    ">
                      Fecha de vencimiento
                    </td>

                    <td align="right" style="
                      padding: 15px;
                      color: #d97706;
                      font-size: 14px;
                      font-weight: bold;
                      border-bottom: 1px solid #e8eeea;
                    ">
                      ${fechaTexto}
                    </td>
                  </tr>

                  <tr>
                    <td style="
                      padding: 15px;
                      color: #78877f;
                      font-size: 14px;
                    ">
                      Estado de la cuota
                    </td>

                    <td align="right" style="
                      padding: 15px;
                      color: #d97706;
                      font-size: 14px;
                      font-weight: bold;
                    ">
                      Pendiente
                    </td>
                  </tr>

                </table>

                <!-- AVISO IMPORTANTE -->
                <table width="100%" cellpadding="0" cellspacing="0"
                  border="0" style="
                    margin-top: 25px;
                    background-color: #fff8e8;
                    border-radius: 10px;
                    border-left: 4px solid #e9a23b;
                  ">
                  <tr>
                    <td style="
                      padding: 18px;
                      color: #76551d;
                      font-size: 13px;
                      line-height: 1.7;
                    ">
                      <strong>¡Ten presente!</strong><br>
                      Te recomendamos realizar tu pago antes de
                      la fecha de vencimiento para mantener tus
                      obligaciones al día.
                    </td>
                  </tr>
                </table>

                <!-- DESPEDIDA -->
                <p style="
                  margin: 28px 0 15px;
                  color: #66756d;
                  font-size: 14px;
                  line-height: 1.8;
                ">
                  Si ya realizaste tu pago, puedes hacer caso omiso
                  de este mensaje. Agradecemos tu confianza.
                </p>

                <p style="
                  margin: 0 0 5px;
                  color: #66756d;
                  font-size: 14px;
                ">
                  Cordialmente,
                </p>

                <p style="
                  margin: 0 0 25px;
                  color: #087f5b;
                  font-size: 17px;
                  font-weight: bold;
                ">
                  Equipo Cobra tech
                </p>

              </td>
            </tr>

            <!-- PIE DE PÁGINA -->
            <tr>
              <td align="center" style="
                padding: 25px 20px;
                background-color: #f7faf8;
                border-top: 1px solid #e8eeea;
              ">

                <p style="
                  margin: 0 0 8px;
                  color: #087f5b;
                  font-size: 16px;
                  font-weight: bold;
                  letter-spacing: 1px;
                ">
                  COBRA TECH
                </p>

                <p style="
                  margin: 0;
                  color: #89968f;
                  font-size: 11px;
                  line-height: 1.7;
                ">
                  Este correo fue generado automáticamente
                  por el sistema de gestión de cobranzas.
                  <br>
                  Por favor, no respondas directamente a este mensaje.
                </p>

                <p style="
                  margin: 15px 0 0;
                  color: #a5afa9;
                  font-size: 10px;
                ">
                  © Cobra tech - Todos los derechos reservados.
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
        from: 'Cobra tech <onboarding@resend.dev>',
        to: [destinatario],
        subject: 'Recordatorio de pago - Cobra tech',

        // ÚNICO AGREGADO: diseño HTML.
        html: crearCorreoHTML(cuota, valorTexto, fechaTexto),

        text: [
          'Hola,',
          '',
          'Este es un recordatorio de pago de Cobra tech.',
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
