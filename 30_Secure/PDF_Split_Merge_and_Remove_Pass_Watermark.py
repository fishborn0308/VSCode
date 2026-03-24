#!/usr/bin/env python3
# SAN教育で配布されるPDFのパスワード解除、個人情報の消去
# Linux
# PDFの暗号化解除
# - ツールの準備
#   - Linux:`apt install qpdf`
#   - Mac:`brew install qpdf`
# - 引数
#   - `in-ps.pdf`：暗号化されたpdfファイル名
#   - `PASSWORD`：SANSから提供されたパスワード
#   - `out-nops.pdf`：複合化されて出力されるpdfファイル名
# - コマンド例
#   - `qpdf --decrypt in-ps.pdf --password=PASSWORD out-nops.pdf`
# PDFの分割・結合
# - グーグル翻訳では10MB以下でないと無料でできないため、PDFを分割・結合する。
# - ツールの準備
#   - Linux:`apt install pdftk`
#   - Mac:`brew install pdftk-java`
# - 引数
#   - `in-pdf`：対象のPDFファイル
#   - `page-range`：ページ範囲
#   - `out-pdf`：出力先のPDFファイル
# - 分割
#   - `pdftk in-pdf cat page-range output out-pdf`
#     - pdftk BOOK-1_re.pdf cat 1-100 output Book1_1.pdf
#     - pdftk BOOK-1_re.pdf cat 101-end output Book1_2.pdf
# - 結合
#   - `pdftk in-pdf1 in-pdf2 cat output out-pdf`
#    - pdftk Book1_1.pdf Book1_2.pdf cat output Book1_jp.pdf
# 個人情報等文字列の削除　※pythonで実装した
# - ツールの準備(GUIツールなので以下のみでは足りないかもしれないので適宜追加等必要)
#   - Linux:`pip install pdfminer PyPDF4`
#   - Mac:`pip3 install pdfminer PyPDF4`
#     - OSのシステム環境を保護するために、pip3 install を直接実行すると「error: externally-managed-environment」というエラーが出てインストールがブロックされる仕様になっているため、`pip3 install --user pdfminer PyPDF4` としてユーザーローカルにインストールする必要があります。
#     - もしくは仮想環境を作成して、その中でインストールする方法もあります。
# - 個人情報などの文字列の削除・実行
#   - `python3 remove.py [inputFile] [outputFile]`

from PyPDF4 import PdfFileReader, PdfFileWriter
from pdfminer.pdfinterp import PDFResourceManager
from pdfminer.converter import TextConverter
from pdfminer.pdfinterp import PDFPageInterpreter
from pdfminer.pdfpage import PDFPage
from pdfminer.layout import LAParams
from io import StringIO
import argparse


class PDFWatermarkRemover:
    def __init__(self, inputfile, outputfile='output.pdf'):
        self.inputfile = inputfile
        self.outputfile = outputfile

    def remove_watermark(self):
        with open(self.inputfile, "rb") as pdf_file:
            output = StringIO()
            resource_manager = PDFResourceManager()
            laparams = LAParams()
            text_converter = TextConverter(resource_manager, output, laparams=laparams)
            page_interpreter = PDFPageInterpreter(resource_manager, text_converter)

            for i_page in PDFPage.get_pages(pdf_file):
                page_interpreter.process_page(i_page)
                break

            output_text = output.getvalue()
            output.close()
            text_converter.close()

        wordlist = output_text.split('\n\n')
        print(wordlist)
        pdf_reader = PdfFileReader(open(self.inputfile, 'rb'), strict=False)

        output_pdf = PdfFileWriter()
        num_pages = pdf_reader.numPages

        for cp in range(num_pages):
            page = pdf_reader.getPage(cp)
            output_pdf.addPage(page)

        for i in range(0, 7):
            output_pdf.removeText(wordlist[i])
            print(wordlist[i])
        print(wordlist[8])

        with open(self.outputfile, 'wb') as output_stream:
            output_pdf.write(output_stream)


def main():
    parser = argparse.ArgumentParser(description='watermark remover')
    parser.add_argument('-i', '--inputfile', type=str, required=True, help='input file name')
    parser.add_argument('-o', '--outputfile', type=str, help='output filename (default is output.pdf)', default='output.pdf')
    args = parser.parse_args()

    remover = PDFWatermarkRemover(args.inputfile, args.outputfile)
    remover.remove_watermark()


if __name__ == "__main__":
    main()  
