const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/solicitacoesController');
const { validar } = require('../middlewares/validacao');

const router = Router();

const validarCriar = [
  body('usuario_id').isInt({ min: 1 }).withMessage('usuario_id deve ser um inteiro positivo.'),
  body('tipo_servico').notEmpty().withMessage('tipo_servico é obrigatório.'),
  body('descricao').isLength({ min: 10 }).withMessage('descricao deve ter pelo menos 10 caracteres.'),
  body('endereco').notEmpty().withMessage('endereco é obrigatório.'),
];

const validarId = [
  param('id').isInt({ min: 1 }).withMessage('ID deve ser um inteiro positivo.'),
];

const validarStatus = [
  param('id').isInt({ min: 1 }).withMessage('ID deve ser um inteiro positivo.'),
  body('status')
    .notEmpty()
    .withMessage('status é obrigatório.')
    .isIn(['ACEITO', 'EM_ANDAMENTO', 'CONCLUIDO', 'RECUSADO'])
    .withMessage('status inválido.'),
];


router.post('/', validarCriar, validar, ctrl.criar);
router.get('/', ctrl.listar);
router.get('/:id', validarId, validar, ctrl.buscarPorId);
router.patch('/:id/status', validarStatus, validar, ctrl.atualizarStatus);

module.exports = router;
