from weasyprint import HTML
html = HTML(string='<html><body><h1>Hello, world</h1></body></html>')
html.write_pdf('output.pdf')
