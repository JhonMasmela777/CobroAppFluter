
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { Resend } = require('resend');

// ======================================================
// CONFIGURACIÓN
// ======================================================

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

// ======================================================
// FECHAS Y FORMATO COLOMBIA
// ======================================================

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

  return new Date(
    Date.UTC(
      Number(partes.year),
      Number(partes.month) - 1,
      Number(partes.day),
      5, 0, 0, 0
    )
  );
}

function fechaColombia(fecha) {
  return new Intl.DateTimeFormat('es-CO', {
    timeZone: 'America/Bogota',
    dateStyle: 'long',
  }).format(fecha);
}

function escaparHTML(valor) {
  return String(valor)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// ======================================================
// PLANTILLA DEL CORREO
// ======================================================

function crearPlantillaCorreo({
  nombre,
  numeroCuota,
  valorTexto,
  fechaVencimiento,
}) {
  const nombreSeguro = escaparHTML(nombre || 'cliente');
  const cuotaSegura = escaparHTML(numeroCuota);
  const valorSeguro = escaparHTML(valorTexto);
  const fechaSegura = escaparHTML(fechaVencimiento);

  const html = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Recordatorio de pago | Cobramzas</title>
</head>
<body style="margin:0;padding:0;background-color:#f1f5f9;font-family:Arial,Helvetica,sans-serif;color:#1e293b;">

  <div style="display:none;font-size:1px;color:#f1f5f9;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">
    Le recordamos amablemente la próxima fecha de vencimiento de su cuota.
  </div>

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0"
    style="background-color:#f1f5f9;padding:30px 12px;">
    <tr>
      <td align="center">

        <table role="presentation" width="100%" cellspacing="0" cellpadding="0"
          style="max-width:600px;background-color:#ffffff;border-radius:14px;overflow:hidden;">

          <tr>
            <td style="background-color:#166534;padding:28px 30px;text-align:center;">
              <div style="font-size:29px;font-weight:bold;color:#ffffff;letter-spacing:1px;">
                Cobramzas
              </div>
              <div style="font-size:13px;color:#dcfce7;margin-top:8px;">
                Gestión de créditos y cobranzas
              </div>
            </td>
          </tr>

          <tr>
            <td style="padding:32px 30px 18px;">

              <h1 style="font-size:22px;color:#166534;margin:0 0 20px;">
                Recordatorio de pago
              </h1>

              <p style="font-size:15px;line-height:1.7;margin:0 0 14px;">
                Apreciado cliente <strong>${nombreSeguro}</strong>:
              </p>

              <p style="font-size:15px;line-height:1.7;margin:0 0 14px;">
                Reciba un cordial saludo de parte de Cobramzas.
                Nos permitimos recordarle amablemente que su cuota
                tiene una fecha de vencimiento próxima. Le invitamos
                a ponerse al día con su obligación en la fecha establecida.
              </p>

              <p style="font-size:15px;line-height:1.7;margin:0 0 22px;">
                A continuación, encontrará los detalles de su cuota:
              </p>

              <table role="presentation" width="100%" cellspacing="0" cellpadding="0"
                style="background-color:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;">
                <tr>
                  <td style="padding:20px;">

                    <div style="font-size:13px;color:#64748b;margin-bottom:6px;">
                      Valor de la cuota
                    </div>

                    <div style="font-size:28px;font-weight:bold;color:#166534;margin-bottom:20px;">
                      ${valorSeguro}
                    </div>

                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                      <tr>
                        <td style="padding:10px 0;border-top:1px solid #d1fae5;font-size:14px;color:#64748b;">
                          Número de cuota
                        </td>
                        <td align="right" style="padding:10px 0;border-top:1px solid #d1fae5;font-size:14px;font-weight:bold;">
                          ${cuotaSegura}
                        </td>
                      </tr>

                      <tr>
                        <td style="padding:10px 0;border-top:1px solid #d1fae5;font-size:14px;color:#64748b;">
                          Fecha de vencimiento
                        </td>
                        <td align="right" style="padding:10px 0;border-top:1px solid #d1fae5;font-size:14px;font-weight:bold;">
                          ${fechaSegura}
                        </td>
                      </tr>
                    </table>

                  </td>
                </tr>
              </table>

              <p style="font-size:14px;line-height:1.7;margin:22px 0 14px;">
                Si ya realizó el pago, puede hacer caso omiso a este
                recordatorio. Si tiene alguna inquietud, comuníquese
                con el responsable de su crédito por los canales habituales.
              </p>

              <p style="font-size:14px;line-height:1.7;margin:0;">
                Agradecemos su atención y confianza.
              </p>

              <p style="font-size:14px;line-height:1.7;margin:22px 0 0;">
                Cordialmente,<br>
                <strong style="color:#166534;">Equipo de Cobramzas</strong>
              </p>

            </td>
          </tr>

          <tr>
            <td style="background-color:#f8fafc;border-top:1px solid #e2e8f0;padding:20px 25px;text-align:center;">
              <p style="font-size:12px;line-height:1.6;color:#64748b;margin:0;">
                Mensaje generado por el sistema de gestión de créditos y cobranzas Cobramzas.
                <br>Correo de demostración académica.
              </p>
            </td>
          </tr>

        </table>

      </td>
    </tr>
  </table>

</body>
</html>`;

  const text = [
    `Apreciado cliente ${nombre || 'cliente'}:`,
    '',
    'Reciba un cordial saludo de parte de Cobramzas.',
    'Le recordamos amablemente la próxima fecha de vencimiento de su cuota.',
    'Le invitamos a ponerse al día con su obligación en la fecha establecida.',
    '',
    `Número de cuota: ${numeroCuota}`,
    `Valor: ${valorTexto}`,
    `Fecha de vencimiento: ${fechaVencimiento}`,
    '',
    'Si ya realizó el pago, puede hacer caso omiso a este recordatorio.',
    '',
    'Cordialmente,',
    'Equipo de Cobramzas',
    '',
    'Correo de demostración académica.',
  ].join('\n');

  return { html, text };
}

// ======================================================
// CONSULTAR CUOTAS PENDIENTES
// ======================================================

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

    const clienteDoc = await db
      .collection('clientes')
      .doc(cuota.idCliente)
      .get();

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

    // Si no está habilitado el envío, solo simula el proceso.
    if (!resend) {
      console.log(
        'Modo simulación: no se envió correo ni se modificó Firestore.'
      );
      continue;
    }

    if (!cliente.correoElectronico) {
      console.log(`Cuota ${doc.id}: cliente sin correo registrado.`);
      continue;
    }

    // IMPORTANTE: el correo siempre se envía al correo de prueba.
    // No se envía al correo real del cliente.
    const { html, text } = crearPlantillaCorreo({
      nombre: cliente.nombreCompleto || 'cliente',
      numeroCuota,
      valorTexto,
      fechaVencimiento: fechaColombia(vencimiento),
    });

    const { data, error } = await resend.emails.send({
      from: 'Cobramzas <onboarding@resend.dev>',
      to: [correoPrueba],
      subject: 'Cobramzas | Recordatorio de pago de su cuota',
      html,
      text,
    });

    if (error) {
      console.error(
        `Error enviando prueba para cuota ${doc.id}:`,
        error
      );
      continue;
    }

    console.log(
      `Resend aceptó la prueba para cuota ${doc.id}. ID: ${data?.id}`
    );
  }

  console.log('Proceso finalizado.');
}

// ======================================================
// EJECUCIÓN PRINCIPAL
// ======================================================

consultarCuotasPendientes().catch((error) => {
  console.error('Error consultando las cuotas:', error);
  process.exitCode = 1;
});
