Flights Scraping
----------------------------------------------------------------
<p>
First of all download the dataset Dati di Traffico 2019 from
<a href="https://www.enac.gov.it/pubblicazioni/dati-di-traffico-2019">ENAC </a>
and the airports dataset from
<a href="https://openflights.org/data.html">Openflights </a>.
In the following we will refer to the ENAC dataset as <em>Dati Di Traffico 2019.pdf </em>
while to the Openflights dataset as <em>airports.csv</em>.
<br>
<p>
First of all split the pdf <em>Dati Di Traffico 2019.pdf </em> in pages inside the folder <em>/splitpdf/</em>.
You can use, for example, <bold>pdftk</bold> via the following command line:
<br>
<code>
sudo apt-get install pdftk <br>
pdftk Dati Di Traffico 2019.pdf burst output splitpdf/%d.pdf
</code>
<br>
<p>
After the pdf file has been split, you have to convert the relevant pages (manual inspection)
into csv. One way to do this is to convert the page into images (.png) and then
to csv. The image to csv conversion can be do online (online OCR) or local with <bold>Tesseract</bold>.
The conversion pdf to image can be done with the following code in python:
<code>
from pdf2image import convert_from_path<br>
for x in range(1,18):<br>
&nbsp page = convert_from_path('splitpdf/{num}.pdf'.format(num = str(x))) <br>
&nbsp page[0].save('pdf2image/' + str(x) + '.png',"PNG")
</code>
<br>
<p>
Once the single file have been converted into csv format, you have to join them.<br>
Use <code>csvstack</code> from <code>csvkit</code>:
<br>
<code> 
csvstack csvs/*.csv  > csvs/merge.csv
</code>
<br>
<p>
