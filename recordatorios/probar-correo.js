const { Resend } = require('resend');

async function probarCorreo() {
  const apiKey = process.env.RESEND_API_KEY;

  if (!apiKey) {
    throw new Error('Falta configurar RESEND_API_KEY en GitHub Secrets.');
  }

  const resend = new Resend(apiKey);

  const { data, error } = await resend.emails.send({
    from: 'Cobramzas <onboarding@resend.dev>',
    to: ['jonathancoloradomasmela@gmail.com'],
    subject: 'Prueba de correo - Cobramzas',
    text: [
      '¡Hola!',
      '',
      'Este es un correo de prueba de Cobramzas.',
      'Estamos verificando la integración con Resend para preparar los recordatorios de cuotas.',
      '',
      'Todavía no se han activado los recordatorios automáticos para los clientes.',
      '',
      'Saludos,',
      'Sistema Cobramzas',
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
