const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/usuariosController');
const { validar } = require('../middlewares/validacao');

const router = Router();

router.post('/registrar',
  [
    body('nome').notEmpty().withMessage('nome é obrigatório.'),
    body('email').isEmail().withMessage('email inválido.'),
    body('telefone').optional({ checkFalsy: true })
      .isMobilePhone('pt-BR').withMessage('telefone inválido.'),
    body('senha').isLength({ min: 6 }).withMessage('senha deve ter pelo menos 6 caracteres.'),
  ],
  validar,
  ctrl.registrar
);

router.post('/login',
  [
    body('email').isEmail().withMessage('email inválido.'),
    body('senha').notEmpty().withMessage('senha é obrigatória.'),
  ],
  validar,
  ctrl.login
);

router.get('/:id',
  [param('id').isInt({ min: 1 }).withMessage('ID inválido.')],
  validar,
  ctrl.buscarPorId
);

module.exports = router;
