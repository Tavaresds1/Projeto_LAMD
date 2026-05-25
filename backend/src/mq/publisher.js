const amqp = require('amqplib');

let canal = null;

async function conectar() {
  if (canal) return canal;

  const conexao = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://guest:guest@localhost:5672');
  canal = await conexao.createChannel();
  console.log('[MQ] Conectado ao RabbitMQ');
  return canal;
}

async function publicar(fila, payload) {
  try {
    const ch = await conectar();
    await ch.assertQueue(fila, { durable: true });
    ch.sendToQueue(fila, Buffer.from(JSON.stringify(payload)), { persistent: true });
    console.log(`[MQ] Evento publicado → fila: ${fila}`, payload);
  } catch (err) {
    console.error(`[MQ] Erro ao publicar na fila "${fila}":`, err.message);
  }
}

module.exports = { publicar };
