const { Resend } = require('resend');

async function probarCorreo() {
  const apiKey = process.env.RESEND_API_KEY;

  if (!apiKey) {
    throw new Error('Falta configurar RESEND_API_KEY en GitHub Secrets.');
  }

  const resend = new Resend(apiKey);

  const { data, error } = await resend.emails.send({
    from: 'Cobra Tech <onboarding@resend.dev>',
    to: ['jonathancoloradomasmela@gmail.com'],
    subject: 'Prueba de correo - Cobra tech',
    text: [
      '¡Hola!',
      '',
      'Este es un correo de prueba de Coba tech.',
      'Estamos verificando la integración con Resend para preparar los recordatorios de cuotas.',
      '',
      'Todavía no se han activado los recordatorios automáticos para los clientes.',
      '',
      'Saludos,',
      'Sistema Cobra tech',
    ].join('\n'),
  });

  if (error) {
    console.error('Resend no pudo enviar el correo:', error);
    process.exitCode = 1;
    return;
  }

  console.log('Resend aceptó la solicitud de envío.');
  console.log('Identificador del correo:', data?.id);
}

probarCorreo().catch((error) => {
  console.error('Error en la prueba:', error);
  process.exitCode = 1;
});
