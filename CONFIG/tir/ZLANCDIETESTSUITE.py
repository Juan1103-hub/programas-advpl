import unittest

from ZLANCDIETESTCASE import ZLANCDIE

suite = unittest.TestSuite()

suite.addTest(ZLANCDIE('test_ZLANCDIE_CT001'))
suite.addTest(ZLANCDIE('test_ZLANCDIE_CT002'))
suite.addTest(ZLANCDIE('test_ZLANCDIE_CT003'))
suite.addTest(ZLANCDIE('test_ZLANCDIE_CT004'))
suite.addTest(ZLANCDIE('test_ZLANCDIE_CT005'))

runner = unittest.TextTestRunner(verbosity=2)
runner.run(suite)
