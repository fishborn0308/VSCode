#!/usr/bin/env python3
# - 準備
#   - `pip3 install pycryptodome`
#   - `pip install PyPDF2`
# - 引数
#   - `in-ps.pdf`：暗号化されたpdfファイル名
#   - `PASSWORD`：SANSから提供されたパスワード
# - コマンド例
#   - `python3 ./decrypt.py -i in-ps.pdf -p PASSWORD`
import os
import argparse
from PyPDF2 import PdfReader, PdfWriter

class decrypt(object):
		def __init__(self,infile,password):
				self.infile = infile
				self.password = password

		def process(self):
				reader = PdfReader(self.infile)
				if reader.is_encrypted:
						reader.decrypt(self.password)

				writer = PdfWriter()
				for page in reader.pages:
						writer.add_page(page)

				with open(os.path.splitext(os.path.basename(self.infile))[0] +
						"_decrypted.pdf", "wb") as f:
						writer.write(f)

if __name__ == '__main__':
		parser = argparse.ArgumentParser(
				prog = 'decrypt.py',
				usage = 'decrypt usage',
				description = 'decrypt for pdf with password',
				epilog = 'end',
				add_help = True
		)
		parser.add_argument('-i','--infile',help='input pdf file',required=True)
		parser.add_argument('-p','--password',help='decrypt password',required=True)

		args=parser.parse_args()
		args_dict=vars(args)
		run=decrypt(**args_dict)
		run.process()
