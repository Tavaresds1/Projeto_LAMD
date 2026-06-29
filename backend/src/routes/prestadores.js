const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/prestadoresController');
const { validar } = require('../middlewares/validacao');

const router = Router();

router.get('/', ctrl.listar);
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
router.post('/',
  [
    body('nome').notEmpty().withMessage('nome é obrigatório.'),
    body('email').isEmail().withMessage('email inválido.'),
    body('telefone').optional().isMobilePhone('pt-BR').withMessage('telefone inválido.'),
  ],
  validar,
  ctrl.criar
);

module.exports = router;
