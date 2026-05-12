const { validationResult } = require('express-validator');

// Middleware genérico que retorna os erros de validação do express-validator
function validar(req, res, next) {
  const erros = validationResult(req);
  if (!erros.isEmpty()) {
    return res.status(422).json({
      erro: 'Dados inválidos.',
      detalhes: erros.array().map((e) => ({ campo: e.path, mensagem: e.msg })),
    });
  }
  next();
}

module.exports = { validar };
