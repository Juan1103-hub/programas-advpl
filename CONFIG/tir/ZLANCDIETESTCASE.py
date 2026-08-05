from tir import Webapp
import unittest

class ZLANCDIE(unittest.TestCase):
    """
    TIR E2E Tests for ZLANCDIE - Lancamento de Diesel
    Module: SIGACOM
    Tables: ZD1
    Browse: FWMBrowse + SetDataTable (array mode)
    Buttons: Incluir, Alterar, Visualizar, Excluir, Pesquisar
    """

    @classmethod
    def setUpClass(inst):
        inst.oHelper = Webapp()
        inst.oHelper.Setup('SIGACOM', '02/07/2026', 'T1', '01 02 ')
        inst.oHelper.Program('U_ZLANCDIE')

    def test_ZLANCDIE_CT001(self):
        """CT001 — Incluir lancamento com campos obrigatorios"""
        self.oHelper.SetButton('Incluir')
        self.oHelper.SetValue('Data', '02/07/2026')
        self.oHelper.SetValue('Produto', '000001')
        self.oHelper.SetValue('Litros', '150,00')
        self.oHelper.SetValue('Odometro', '50000')
        self.oHelper.SetValue('Placa', 'ABC1234')
        self.oHelper.SetValue('Motorista', 'JOAO SILVA')
        self.oHelper.SetButton('OK')
        self.oHelper.AssertTrue()

    def test_ZLANCDIE_CT002(self):
        """CT002 — Validar litros obrigatorio (negativo)"""
        self.oHelper.SetButton('Incluir')
        self.oHelper.SetValue('Data', '02/07/2026')
        self.oHelper.SetValue('Produto', '000001')
        self.oHelper.SetValue('Placa', 'ABC1234')
        self.oHelper.SetButton('OK')
        self.oHelper.AssertFalse()

    def test_ZLANCDIE_CT003(self):
        """CT003 — Validar produto obrigatorio (negativo)"""
        self.oHelper.SetButton('Incluir')
        self.oHelper.SetValue('Data', '02/07/2026')
        self.oHelper.SetValue('Litros', '150,00')
        self.oHelper.SetValue('Placa', 'ABC1234')
        self.oHelper.SetButton('OK')
        self.oHelper.AssertFalse()

    def test_ZLANCDIE_CT004(self):
        """CT004 — Validar placa obrigatoria (negativo)"""
        self.oHelper.SetButton('Incluir')
        self.oHelper.SetValue('Data', '02/07/2026')
        self.oHelper.SetValue('Produto', '000001')
        self.oHelper.SetValue('Litros', '150,00')
        self.oHelper.SetButton('OK')
        self.oHelper.AssertFalse()

    def test_ZLANCDIE_CT005(self):
        """CT005 — Pesquisar por placa via ParamBox"""
        self.oHelper.SetButton('Pesquisar')
        self.oHelper.SetValue('Placa', 'ABC1234')
        self.oHelper.SetButton('Ok')
        self.oHelper.AssertTrue()

    @classmethod
    def tearDownClass(inst):
        inst.oHelper.TearDown()

if __name__ == '__main__':
    unittest.main()
