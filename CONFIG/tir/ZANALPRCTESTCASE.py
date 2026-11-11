from tir import Webapp
import unittest

class ZANALPRC(unittest.TestCase):
    """
    Testes TIR (interface/e2e) da rotina ZANALPRC - Analise de Variacao de
    Precos de Compras.

    Modulo.....: SIGACOM
    Tabelas....: SD1 (notas de entrada), SC7 (pedidos de compra), SB1, SA2, CTT, SE4
    Telas......: ParamBox de periodo/comprador/centro de custo, dialogo da
                 analise (grid + filtros + botoes) e dialogo do historico do item.

    Observacao: os rotulos usados em SetValue sao os textos exibidos na tela
    (SAY que precede cada campo). Caso algum rotulo mude na tela, ajustar aqui.
    """

    @classmethod
    def setUpClass(inst):
        inst.oHelper = Webapp()
        inst.oHelper.Setup('SIGACOM', '21/09/2026', 'T1', '01 02 ')
        inst.oHelper.Program('U_ZANALPRC')

    def test_ZANALPRC_CT001(self):
        """CT001 — Abre a analise com periodo valido e exibe o grid."""
        self.oHelper.SetValue('Data Inicial', '01/09/2026')
        self.oHelper.SetValue('Data Final', '21/09/2026')
        self.oHelper.SetButton('Ok')
        self.oHelper.AssertTrue()

    def test_ZANALPRC_CT002(self):
        """CT002 — Negativo: data final anterior a data inicial."""
        self.oHelper.SetButton('Nova Consulta')
        self.oHelper.SetValue('Data Inicial', '21/09/2026')
        self.oHelper.SetValue('Data Final', '01/09/2026')
        self.oHelper.SetButton('Ok')
        self.oHelper.AssertFalse()

    def test_ZANALPRC_CT003(self):
        """CT003 — Negativo: periodo em branco."""
        self.oHelper.SetButton('Nova Consulta')
        self.oHelper.SetValue('Data Inicial', '  /  /    ')
        self.oHelper.SetValue('Data Final', '  /  /    ')
        self.oHelper.SetButton('Ok')
        self.oHelper.AssertFalse()

    def test_ZANALPRC_CT004(self):
        """CT004 — Filtro de variacao: abre a analise e filtra por situacao."""
        self.oHelper.SetButton('Nova Consulta')
        self.oHelper.SetValue('Data Inicial', '01/09/2026')
        self.oHelper.SetValue('Data Final', '21/09/2026')
        self.oHelper.SetButton('Ok')
        self.oHelper.SetValue('Varia', 'Somente Aumentou')
        self.oHelper.AssertTrue()

    def test_ZANALPRC_CT005(self):
        """CT005 — Botao Indicadores abre a janela de indicadores gerenciais."""
        self.oHelper.SetButton('Indicadores')
        self.oHelper.AssertTrue()
        self.oHelper.SetButton('Cancelar')

    def test_ZANALPRC_CT006(self):
        """CT006 — Botao Ver Historico abre o historico do item selecionado."""
        self.oHelper.SetButton('Ver Hist')
        self.oHelper.AssertTrue()
        self.oHelper.SetButton('Cancelar')

    def test_ZANALPRC_CT007(self):
        """CT007 — Botao Excel abre o dialogo de impressao da exportacao."""
        self.oHelper.SetButton('Excel')
        self.oHelper.AssertTrue()
        self.oHelper.SetButton('Cancelar')

    @classmethod
    def tearDownClass(inst):
        inst.oHelper.TearDown()

if __name__ == '__main__':
    unittest.main()
