require('dotenv').config();
const amqp = require('amqplib');

const FILAS = ['solicitacao.criada', 'solicitacao.aceita', 'status.atualizado'];

async function iniciarConsumer() {
  const conexao = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://guest:guest@localhost:5672');
  const canal = await conexao.createChannel();

  console.log('[CONSUMER] Conectado ao RabbitMQ. Aguardando mensagens...\n');

  for (const fila of FILAS) {
    await canal.assertQueue(fila, { durable: true });
    canal.consume(fila, (msg) => {
      if (!msg) return;
      const payload = JSON.parse(msg.content.toString());
      console.log(`[CONSUMER] ← ${fila}`);
      console.log('  Payload:', JSON.stringify(payload, null, 2));
      console.log('  Recebido em:', new Date().toISOString());
      console.log('---');
      canal.ack(msg);
    });
    console.log(`[CONSUMER] Escutando fila: ${fila}`);
  }
}

iniciarConsumer().catch((err) => {
  console.error('[CONSUMER] Erro ao iniciar:', err.message);
  process.exit(1);
});
