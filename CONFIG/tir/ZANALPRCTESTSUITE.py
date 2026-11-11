import unittest

from ZANALPRCTESTCASE import ZANALPRC

suite = unittest.TestSuite()

suite.addTest(ZANALPRC('test_ZANALPRC_CT001'))
suite.addTest(ZANALPRC('test_ZANALPRC_CT002'))
suite.addTest(ZANALPRC('test_ZANALPRC_CT003'))
suite.addTest(ZANALPRC('test_ZANALPRC_CT004'))
suite.addTest(ZANALPRC('test_ZANALPRC_CT005'))
suite.addTest(ZANALPRC('test_ZANALPRC_CT006'))
suite.addTest(ZANALPRC('test_ZANALPRC_CT007'))

runner = unittest.TextTestRunner(verbosity=2)
runner.run(suite)
